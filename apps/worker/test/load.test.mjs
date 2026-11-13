import test from "node:test";
import assert from "node:assert/strict";
import { createPublicKey, verify } from "node:crypto";
import { execFile } from "node:child_process";
import { readFile } from "node:fs/promises";
import { promisify } from "node:util";
import { handleRequest } from "../src/index.js";
import { buildCanonicalCatalog } from "../catalog/catalog-v3.canonical.js";

const execFileAsync = promisify(execFile);

test("GET /v1/load streams exactly 10 MB without cache", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/load"));

  assert.equal(response.status, 200);
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.equal(response.headers.get("content-type"), "application/octet-stream");
  assert.equal((await response.arrayBuffer()).byteLength, 10 * 1024 * 1024);
});

test("the load endpoint refuses other paths and methods", async () => {
  assert.equal((await handleRequest(new Request("https://example.workers.dev/v1/other"))).status, 404);
  const response = await handleRequest(new Request("https://example.workers.dev/v1/load", { method: "POST" }));
  assert.equal(response.status, 405);
  assert.equal(response.headers.get("allow"), "GET");
});

test("the Worker no longer serves the catalog", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/catalog.json"));
  assert.equal(response.status, 404);
});

test("artwork is served only through an allowlisted static-asset path", async () => {
  const seen = [];
  const response = await handleRequest(
    new Request("https://example.workers.dev/artwork/games/fortnite.jpg"),
    { ASSETS: { fetch: async request => { seen.push(new URL(request.url).pathname); return new Response("image", { headers: { "Content-Type": "image/jpeg" } }); } } }
  );
  assert.equal(response.status, 200);
  assert.deepEqual(seen, ["/games/fortnite.jpg"]);
  assert.equal((await handleRequest(new Request("https://example.workers.dev/artwork/../src/index.js"), { ASSETS: { fetch() { throw new Error("must not fetch"); } } })).status, 404);
  assert.equal((await handleRequest(new Request("https://example.workers.dev/artwork/games/fortnite.jpg", { method: "POST" }))).status, 405);
});

test("canonical v3 covers every artwork, platform context and signed AWS fallback", () => {
  const catalog = buildCanonicalCatalog();
  assert.equal(catalog.schemaVersion, 3);
  assert.equal(catalog.games.length, 54);
  for (const game of catalog.games) {
    assert.match(game.artwork.path, /^artwork\/games\/[a-z0-9-]+\.(jpg|png)$/);
    assert.match(game.artwork.sha256, /^[a-f0-9]{64}$/);
    assert.equal(game.rating.status, "pendingVerification");
    assert.ok(game.contexts.length > 0);
    for (const context of game.contexts) {
      assert.equal(context.platforms.length, 1);
      assert.equal(context.routes[0].kind, "gameOwned");
      assert.equal(context.routes[0].status, "pending");
      assert.deepEqual(context.routes[1], {
        id: `${game.id}-${context.platforms[0]}-aws`, kind: "awsFallback", status: "active", regionID: "sa-east-1",
        strategy: "genericRegion", confidence: "medium", precisionKey: "regionalReference"
      });
    }
  }
});

test("canonical v3 references the approved editorial artwork manifest exactly", async () => {
  const manifest = JSON.parse(await readFile(new URL("../catalog/artwork-manifest.json", import.meta.url), "utf8"));
  const approved = new Map(manifest.items.map(item => [item.gameID, item]));
  for (const game of buildCanonicalCatalog().games) {
    const item = approved.get(game.id);
    assert.ok(item, `${game.id} missing from artwork manifest`);
    assert.equal(game.artwork.path, `artwork/games/${item.path.split("/").at(-1)}`);
    assert.equal(game.artwork.sha256, item.sha256);
  }
});

test("Decisão 106: o catálogo embutido é o payload canônico puro, sem assinatura nem validade", async () => {
  const canonical = `${JSON.stringify(buildCanonicalCatalog())}\n`;
  const workerCandidate = await readFile(new URL("../catalog/catalog-v3.candidate.json", import.meta.url), "utf8");
  assert.equal(workerCandidate, canonical, "../catalog/catalog-v3.candidate.json difere do payload canônico");

  const bundledPaths = [
    "../../../apps/ios/Sources/NolaggyInfrastructure/Resources/DebugCatalogBase.json",
    "../../../apps/android/app/src/main/assets/catalog-base.json"
  ];
  const bundledTexts = await Promise.all(
    bundledPaths.map(path => readFile(new URL(path, import.meta.url), "utf8"))
  );
  assert.equal(bundledTexts[0], bundledTexts[1], "Catálogo embutido do iOS difere do Android");
  for (const [index, text] of bundledTexts.entries()) {
    const path = bundledPaths[index];
    assert.equal(text.includes("signatureBase64"), false, `${path} não deve conter assinatura`);
    assert.equal(text.includes("expiresAt"), false, `${path} não deve conter validade`);
    const parsed = JSON.parse(text);
    assert.equal(parsed.schemaVersion, 3);
    assert.equal(parsed.assetBaseURL, "https://lagcheck.signallq.com/");
    assert.ok(parsed.regions.length >= 20, `${path} precisa de cobertura regional completa`);
    assert.ok(parsed.games.length >= 56, `${path} deve espelhar o catálogo do site`);
  }
});

test("the schema 2 candidate produces a deterministic external signing request", async () => {
  const { stdout } = await execFileAsync(
    process.execPath,
    [
      "scripts/catalog-signing.mjs",
      "request",
      "catalog/DebugCatalogPayload.schema2.canonical.json",
      "2026-09-19T00:00:00Z",
      "2026-10-19T00:00:00Z"
    ],
    { cwd: new URL("..", import.meta.url) }
  );
  const request = JSON.parse(stdout);
  const candidate = JSON.parse(await readFile(new URL("../catalog/DebugCatalogPayload.schema2.canonical.json", import.meta.url), "utf8"));

  assert.equal(request.schemaVersion, 2);
  assert.equal(request.catalogVersion, candidate.catalogVersion);
  assert.equal(Buffer.from(request.payloadBase64, "base64").toString("utf8"), JSON.stringify(candidate, null, 2));
  assert.equal(candidate.games.length, 22);
  assert.ok(candidate.regions.every((region) => region.probe.protocolKind === "gameLiftPing"));
});
