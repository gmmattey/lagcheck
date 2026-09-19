import test from "node:test";
import assert from "node:assert/strict";
import { createPublicKey, verify } from "node:crypto";
import { readFile } from "node:fs/promises";
import { handleRequest } from "../src/index.js";

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
