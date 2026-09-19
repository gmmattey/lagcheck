#!/usr/bin/env node
import { createHash, createPublicKey, verify } from "node:crypto";
import { readFile } from "node:fs/promises";
import process from "node:process";

// Chave pública distribuída pelo app. A chave privada fica deliberadamente fora
// do checkout, do Worker e deste utilitário.
const RAW_PUBLIC_KEY_BASE64 = "tCsSOLt9B7WpXalcu6iT6CxMrEx3w787rPRR7KXxGso=";
const SPKI_PREFIX = Buffer.from("302a300506032b6570032100", "hex");
const MAX_VALIDITY_MS = 30 * 24 * 60 * 60 * 1000;

function fail(message) {
  throw new Error(message);
}

function usage() {
  return [
    "Uso:",
    "  node scripts/catalog-signing.mjs request <payload.json> <issued-at> <expires-at>",
    "  node scripts/catalog-signing.mjs verify <envelope.json> [payload.json]"
  ].join("\n");
}

function parseJSON(bytes, label) {
  try {
    return JSON.parse(bytes.toString("utf8"));
  } catch {
    fail(`${label} não contém JSON válido.`);
  }
}

function validateMetadata({ schemaVersion, catalogVersion, issuedAt, expiresAt, algorithm }) {
  if (!Number.isInteger(schemaVersion) || schemaVersion < 1) fail("schemaVersion inválido.");
  if (typeof catalogVersion !== "string" || catalogVersion.length === 0) fail("catalogVersion inválido.");
  if (algorithm !== "Ed25519") fail("algorithm deve ser Ed25519.");

  const issued = new Date(issuedAt);
  const expires = new Date(expiresAt);
  if (Number.isNaN(issued.valueOf()) || Number.isNaN(expires.valueOf())) fail("Datas ISO-8601 inválidas.");
  if (expires <= issued || expires - issued > MAX_VALIDITY_MS) fail("A validade deve ser maior que zero e no máximo 30 dias.");
}

function publicKey() {
  const raw = Buffer.from(RAW_PUBLIC_KEY_BASE64, "base64");
  return createPublicKey({ key: Buffer.concat([SPKI_PREFIX, raw]), format: "der", type: "spki" });
}

function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

function canonicalPayloadBytes(fileBytes) {
  if (fileBytes.subarray(0, 3).equals(Buffer.from([0xef, 0xbb, 0xbf]))) fail("O payload canônico não pode ter BOM.");
  if (fileBytes.includes(0x0d)) fail("O payload canônico deve usar somente LF.");
  // O arquivo pode terminar em LF para permanecer amigável ao Git, mas o byte
  // de quebra final não pertence ao JSON assinado. A regra é deliberada e
  // aplicada tanto no pedido quanto na conferência do envelope.
  return fileBytes.at(-1) === 0x0a ? fileBytes.subarray(0, -1) : fileBytes;
}

async function request(payloadPath, issuedAt, expiresAt) {
  const payloadBytes = canonicalPayloadBytes(await readFile(payloadPath));
  const payload = parseJSON(payloadBytes, "O payload canônico");
  validateMetadata({
    schemaVersion: payload.schemaVersion,
    catalogVersion: payload.catalogVersion,
    issuedAt,
    expiresAt,
    algorithm: "Ed25519"
  });

  // Não reserializa JSON: os bytes deste arquivo são exatamente os bytes a
  // serem assinados pelo cofre externo.
  process.stdout.write(`${JSON.stringify({
    schemaVersion: payload.schemaVersion,
    catalogVersion: payload.catalogVersion,
    issuedAt,
    expiresAt,
    algorithm: "Ed25519",
    payloadBase64: payloadBytes.toString("base64"),
    payloadSHA256: sha256(payloadBytes)
  }, null, 2)}\n`);
}

async function verifyEnvelope(envelopePath, payloadPath) {
  const envelope = parseJSON(await readFile(envelopePath), "O envelope");
  validateMetadata(envelope);
  if (typeof envelope.payloadBase64 !== "string" || typeof envelope.signatureBase64 !== "string") {
    fail("Envelope sem payloadBase64 ou signatureBase64.");
  }

  const payloadBytes = Buffer.from(envelope.payloadBase64, "base64");
  const signature = Buffer.from(envelope.signatureBase64, "base64");
  if (payloadBytes.length === 0 || signature.length === 0) fail("Payload ou assinatura vazios.");
  if (!verify(null, payloadBytes, publicKey(), signature)) fail("A assinatura Ed25519 não confere com a chave pública do app.");

  if (payloadPath) {
    const canonicalBytes = canonicalPayloadBytes(await readFile(payloadPath));
    if (!payloadBytes.equals(canonicalBytes)) fail("O envelope não corresponde exatamente aos bytes do payload canônico.");
  }

  const payload = parseJSON(payloadBytes, "O payload do envelope");
  if (payload.schemaVersion !== envelope.schemaVersion || payload.catalogVersion !== envelope.catalogVersion) {
    fail("schemaVersion ou catalogVersion do payload divergem do envelope.");
  }

  process.stdout.write(`${JSON.stringify({
    valid: true,
    catalogVersion: envelope.catalogVersion,
    payloadSHA256: sha256(payloadBytes),
    matchesCanonicalPayload: Boolean(payloadPath)
  }, null, 2)}\n`);
}

const [command, ...args] = process.argv.slice(2);
try {
  if (command === "request" && args.length === 3) {
    await request(args[0], args[1], args[2]);
  } else if (command === "verify" && (args.length === 1 || args.length === 2)) {
    await verifyEnvelope(args[0], args[1]);
  } else {
    fail(usage());
  }
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
}
