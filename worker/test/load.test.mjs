import test from "node:test";
import assert from "node:assert/strict";
import { createPublicKey, verify } from "node:crypto";
import { readFile } from "node:fs/promises";
import { handleRequest } from "../src/index.js";
import { buildCanonicalCatalog } from "../catalog/catalog-v3.canonical.js";

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

test("GET /v1/catalog.json returns the immutable signed Debug envelope", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/catalog.json"));
  const envelope = await response.json();

  assert.equal(response.status, 200);
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.equal(envelope.schemaVersion, 1);
  assert.equal(envelope.catalogVersion, "debug-2026.09.18.1");
  assert.equal(envelope.algorithm, "Ed25519");
  assert.ok(envelope.payloadBase64.length > 0);
  assert.ok(envelope.signatureBase64.length > 0);
});

test("the catalog endpoint permits only GET", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/catalog.json", { method: "POST" }));
  assert.equal(response.status, 405);
  assert.equal(response.headers.get("allow"), "GET");
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
  assert.equal(catalog.games.length, 22);
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

test("the Debug catalog payload is signed by the public key embedded in iOS", async () => {
  const response = await handleRequest(new Request("https://example.workers.dev/v1/catalog.json"));
  const envelope = await response.json();
  const rawPublicKey = Buffer.from("tCsSOLt9B7WpXalcu6iT6CxMrEx3w787rPRR7KXxGso=", "base64");
  const spkiPrefix = Buffer.from("302a300506032b6570032100", "hex");
  const publicKey = createPublicKey({ key: Buffer.concat([spkiPrefix, rawPublicKey]), format: "der", type: "spki" });

  assert.equal(verify(null, Buffer.from(envelope.payloadBase64, "base64"), publicKey, Buffer.from(envelope.signatureBase64, "base64")), true);
});
