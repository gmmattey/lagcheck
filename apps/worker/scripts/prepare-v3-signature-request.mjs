import { writeFile } from "node:fs/promises";
import { buildCanonicalCatalog } from "../catalog/catalog-v3.canonical.js";

const output = process.argv[2];
if (!output) throw new Error("Uso: node scripts/prepare-v3-signature-request.mjs <payload.json>");

// JSON sem espaços e com ordem estável: estes são exatamente os bytes que o
// assinador externo deve receber e assinar com a chave Ed25519 protegida.
await writeFile(output, `${JSON.stringify(buildCanonicalCatalog())}\n`, "utf8");
