import test from "node:test";
import assert from "node:assert/strict";
import { createPublicKey, verify } from "node:crypto";
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

  assert.equal(response.status, 200);
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.equal(envelope.schemaVersion, 1);
  assert.equal(envelope.catalogVersion, "debug-2026.09.08.2");
  assert.equal(envelope.algorithm, "Ed25519");
  assert.ok(envelope.payloadBase64.length > 0);
  assert.ok(envelope.signatureBase64.length > 0);
});

test("the catalog endpoint permits only GET", () => {
  const response = handleRequest(new Request("https://example.workers.dev/v1/catalog.json", { method: "POST" }));
  assert.equal(response.status, 405);
  assert.equal(response.headers.get("allow"), "GET");
});

test("the Debug catalog payload is signed by the public key embedded in iOS", async () => {
  const response = handleRequest(new Request("https://example.workers.dev/v1/catalog.json"));
  const envelope = await response.json();
  const rawPublicKey = Buffer.from("4YJQhLLBC414Nj2gTjeDSqMxoJqsiw4BQeKTCxX5NuI=", "base64");
  const spkiPrefix = Buffer.from("302a300506032b6570032100", "hex");
  const publicKey = createPublicKey({ key: Buffer.concat([spkiPrefix, rawPublicKey]), format: "der", type: "spki" });

  assert.equal(verify(null, Buffer.from(envelope.payloadBase64, "base64"), publicKey, Buffer.from(envelope.signatureBase64, "base64")), true);
});
