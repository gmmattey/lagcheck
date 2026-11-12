import { readFile, writeFile, copyFile, mkdir } from "node:fs/promises";
import { createHash } from "node:crypto";
import { buildCandidateCatalog } from "../catalog/catalog-v3.canonical.js";

// Rebuild only the unsigned candidate. Signing and publication remain external.
const root = new URL("../../", import.meta.url);
const manifest = JSON.parse(await readFile(new URL("../catalog/artwork-manifest.json", import.meta.url)));
const assets = [
  ["dead-by-daylight", "DeadByDaylight"], ["for-honor", "ForHonor"],
  ["borderlands-3", "Borderlands3"], ["new-world", "NewWorld"],
  ["squid-game-unleashed", "SquidGameUnleashed"], ["warhammer-darktide", "WarhammerDarktide"],
  ["marvel-snap", "MarvelSnap"], ["the-outlast-trials", "TheOutlastTrials"],
  ["tribes-of-midgard", "TribesOfMidgard"], ["crossfar", "Crossfar"],
  ["lost-rift", "LostRift"], ["star-wars-hunters", "StarWarsHunters"],
  ["rematch", "Rematch"], ["predecessor", "Predecessor"],
  ["super-mega-baseball-4", "SuperMegaBaseball4"], ["marauders", "Marauders"],
  ["legacy-steel-and-sorcery", "LegacySteelAndSorcery"], ["ninjala", "Ninjala"],
  ["roller-champions", "RollerChampions"], ["ghost-recon-breakpoint", "GhostReconBreakpoint"],
  ["dark-alliance", "DarkAlliance"], ["wolcen-lords-of-mayhem", "WolcenLordsOfMayhem"],
  ["streamline", "Streamline"], ["tacticool", "Tacticool"],
  ["ghost-war", "GhostWar"], ["overwatch-2", "Overwatch2"]
];
for (const [id, asset] of assets) {
  const source = new URL(`../catalog/assets/games/${id}.png`, import.meta.url);
  const bytes = await readFile(source);
  const sha256 = createHash("sha256").update(bytes).digest("hex");
  const item = { gameID: id, path: `assets/games/${id}.png`, mimeType: "image/png", width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20), sha256, status: "ready" };
  manifest.items = manifest.items.filter(existing => existing.gameID !== id);
  manifest.items.push(item);
  const imageSet = new URL(`Sources/NolaggyApp/Assets.xcassets/Game${asset}.imageset/`, root);
  await mkdir(imageSet, { recursive: true });
  await copyFile(source, new URL(`${id}.png`, imageSet));
  await writeFile(new URL("Contents.json", imageSet), JSON.stringify({ images: [{ filename: `${id}.png`, idiom: "universal" }], info: { author: "xcode", version: 1 } }, null, 2) + "\n");
  await copyFile(source, new URL(`design-system/assets/games/${id}.png`, root));
  await copyFile(source, new URL(`android/app/src/main/res/drawable/game_${id.replaceAll("-", "_")}.png`, root));
}
const manifestJSON = `{
  "schemaVersion": ${manifest.schemaVersion},
  "generatedFor": "${manifest.generatedFor}",
  "artworkPolicy": "${manifest.artworkPolicy}",
  "items": [
${manifest.items.map(item => "    " + JSON.stringify(item).replaceAll('":', '": ').replaceAll(',"', ', "')).join(",\n")}
  ]
}\n`;
await writeFile(new URL("../catalog/artwork-manifest.json", import.meta.url), manifestJSON);
await writeFile(new URL("../catalog/catalog-v3.candidate.json", import.meta.url), JSON.stringify(buildCandidateCatalog(manifest)) + "\n");
console.log("Prepared 48-game unsigned candidate and 26 local image sets.");
