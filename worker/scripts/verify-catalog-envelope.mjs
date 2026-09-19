import { readFile } from "node:fs/promises";
import { createPublicKey, verify } from "node:crypto";

const path = process.argv[2];
if (!path) throw new Error("Uso: node scripts/verify-catalog-envelope.mjs <envelope.json>");
const envelope = JSON.parse(await readFile(path, "utf8"));
const rawKey = Buffer.from("oe/5VSQfhWcma+W6DdUzAESJpjgTrLtkXAcT0nEbDwo=", "base64");
const spki = Buffer.from("302a300506032b6570032100", "hex");
const key = createPublicKey({ key: Buffer.concat([spki, rawKey]), format: "der", type: "spki" });
const valid = envelope.schemaVersion === 3 && envelope.algorithm === "Ed25519" &&
  verify(null, Buffer.from(envelope.payloadBase64, "base64"), key, Buffer.from(envelope.signatureBase64, "base64"));
if (!valid) throw new Error("Envelope v3 inválido ou não assinado pela chave pública do app.");
console.log("Envelope v3 válido.");
