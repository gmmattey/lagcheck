#!/usr/bin/env node

/**
 * Falha cedo quando um idioma suportado perde uma chave, uma tradução fica
 * vazia ou uma cópia visível é introduzida diretamente em SwiftUI.
 *
 * Uso: node scripts/verify-localization.mjs
 */
import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join, relative } from "node:path";

const root = process.cwd();
const iosRoot = existsSync(join(root, "apps/ios")) ? join(root, "apps/ios") : root;
const resources = join(iosRoot, "Sources/NolaggyApp/Resources");
const sourceRoot = join(iosRoot, "Sources");
const locales = ["pt-BR", "en", "es"];
// Marcas e símbolos não são cópia traduzível; os demais textos de interface
// precisam ser chaves presentes nos três catálogos.
const allowedVisibleLiterals = new Set(["LagCheck", "Metacritic", "•", "·", "—", ": ", ". ", ", "]);

function stringsFor(locale) {
  const path = join(resources, `${locale}.lproj/Localizable.strings`);
  const json = execFileSync("plutil", ["-convert", "json", "-o", "-", path], { encoding: "utf8" });
  return JSON.parse(json);
}

function swiftFiles(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) return swiftFiles(path);
    return entry.isFile() && path.endsWith(".swift") ? [path] : [];
  });
}

const catalogs = Object.fromEntries(locales.map((locale) => [locale, stringsFor(locale)]));
const baseKeys = new Set(Object.keys(catalogs["pt-BR"]));
const failures = [];

for (const locale of locales) {
  const entries = catalogs[locale];
  const keys = new Set(Object.keys(entries));
  const missing = [...baseKeys].filter((key) => !keys.has(key));
  const unexpected = [...keys].filter((key) => !baseKeys.has(key));
  const blank = [...keys].filter((key) => !String(entries[key]).trim());

  if (missing.length) failures.push(`${locale}: chaves ausentes: ${missing.join(", ")}`);
  if (unexpected.length) failures.push(`${locale}: chaves sem paridade: ${unexpected.join(", ")}`);
  if (blank.length) failures.push(`${locale}: traduções vazias: ${blank.join(", ")}`);
}

const knownKeys = new Set(Object.values(catalogs).flatMap((catalog) => Object.keys(catalog)));
const literalPattern = /(?:Text|Label)\(\s*"([^"\\]+)"|accessibility(?:Label|Hint)\(Text\(\s*"([^"\\]+)"/g;

for (const path of swiftFiles(sourceRoot)) {
  const lines = readFileSync(path, "utf8").split("\n");
  lines.forEach((line, index) => {
    for (const match of line.matchAll(literalPattern)) {
      const literal = match[1] ?? match[2];
      if (!knownKeys.has(literal) && !allowedVisibleLiterals.has(literal)) {
        failures.push(`${relative(root, path)}:${index + 1}: cópia visível fora do catálogo: "${literal}"`);
      }
    }
  });
}

if (failures.length) {
  console.error("Falha na validação de localização:\n" + failures.map((failure) => `- ${failure}`).join("\n"));
  process.exit(1);
}

console.log(`Localização válida: ${baseKeys.size} chaves em ${locales.join(", ")}.`);
