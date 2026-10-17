import { writeFile } from "node:fs/promises";
import { buildCanonicalCatalog } from "../catalog/catalog-v3.canonical.js";

// Emite os bytes exatos a serem assinados. A assinatura nunca é feita aqui.
const payload = `${JSON.stringify(buildCanonicalCatalog())}\n`;
await writeFile(new URL("../catalog/catalog-v3.candidate.json", import.meta.url), payload);
process.stdout.write("Prepared canonical 48-game publication payload.\n");
