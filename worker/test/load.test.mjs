import test from "node:test";
import assert from "node:assert/strict";
import { createPublicKey, verify } from "node:crypto";
import { execFile } from "node:child_process";
import { readFile } from "node:fs/promises";
import { promisify } from "node:util";
import { handleRequest } from "../src/index.js";

const execFileAsync = promisify(execFile);

test("GET /v1/load streams exactly 10 MB without cache", async () => {
  const response = handleRequest(new Request("https://example.workers.dev/v1/load"));

  assert.equal(response.status, 200);
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.equal(response.headers.get("content-type"), "application/octet-stream");
  assert.equal((await response.arrayBuffer()).byteLength, 10 * 1024 * 1024);
});

test("the load endpoint refuses other paths and methods", () => {
  assert.equal(handleRequest(new Request("https://example.workers.dev/v1/other")).status, 404);
  const response = handleRequest(new Request("https://example.workers.dev/v1/load", { method: "POST" }));
  assert.equal(response.status, 405);
  assert.equal(response.headers.get("allow"), "GET");
});

test("GET /v1/catalog.json returns the immutable signed Debug envelope", async () => {
  const response = handleRequest(new Request("https://example.workers.dev/v1/catalog.json"));
  const envelope = await response.json();
  const bundledEnvelope = JSON.parse(await readFile(new URL("../../Sources/NolaggyInfrastructure/Resources/DebugCatalogBase.json", import.meta.url), "utf8"));

  assert.equal(response.status, 200);
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.deepEqual(envelope, bundledEnvelope);
});

test("the catalog endpoint permits only GET", () => {
  const response = handleRequest(new Request("https://example.workers.dev/v1/catalog.json", { method: "POST" }));
  assert.equal(response.status, 405);
  assert.equal(response.headers.get("allow"), "GET");
});

test("the Debug catalog payload is signed by the public key embedded in iOS", async () => {
  const response = handleRequest(new Request("https://example.workers.dev/v1/catalog.json"));
  const envelope = await response.json();
  const rawPublicKey = Buffer.from("tCsSOLt9B7WpXalcu6iT6CxMrEx3w787rPRR7KXxGso=", "base64");
  const spkiPrefix = Buffer.from("302a300506032b6570032100", "hex");
  const publicKey = createPublicKey({ key: Buffer.concat([spkiPrefix, rawPublicKey]), format: "der", type: "spki" });

  assert.equal(verify(null, Buffer.from(envelope.payloadBase64, "base64"), publicKey, Buffer.from(envelope.signatureBase64, "base64")), true);
});

test("the canonical signing input matches the bundled Debug envelope bytes", async () => {
  const canonicalPayload = await readFile(new URL("../catalog/DebugCatalogPayload.canonical.json", import.meta.url));
  const bundledEnvelope = JSON.parse(await readFile(new URL("../../Sources/NolaggyInfrastructure/Resources/DebugCatalogBase.json", import.meta.url), "utf8"));

  assert.deepEqual(Buffer.from(bundledEnvelope.payloadBase64, "base64"), canonicalPayload.subarray(0, -1));
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
