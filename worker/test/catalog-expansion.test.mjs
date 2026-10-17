import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import { buildCanonicalCatalog, catalogExpansionGames } from "../catalog/catalog-v3.canonical.js";

test("canonical publication source has 48 unique games and preserves existing contexts", async () => {
  const candidate = buildCanonicalCatalog();
  const persisted = JSON.parse(await readFile(new URL("../catalog/catalog-v3.candidate.json", import.meta.url)));
  assert.deepEqual(persisted, candidate);
  assert.equal(candidate.games.length, 48);
  assert.equal(new Set(candidate.games.map(game => game.id)).size, 48);
  assert.equal(candidate.regions.length, 21);
  assert.deepEqual(candidate.regions.slice(0, 2).map(region => region.id), ["sa-east-1", "us-east-1"]);
  assert.ok(candidate.regions.every(region =>
    region.probe.host === `gamelift-ping.${region.id}.api.aws` &&
    region.probe.port === 7770 && region.probe.protocolKind === "gameLiftPing"
  ));

  for (const game of candidate.games.slice(22)) {
    const expansionEntry = catalogExpansionGames.find(entry => entry[0] === game.id);
    assert.ok(expansionEntry, `Expansion game missing: ${game.id}`);
    const expectedPlatforms = expansionEntry[2];
    const expectedProfile = expansionEntry[3];
    assert.deepEqual(game.contexts.flatMap(context => context.platforms), expectedPlatforms);
    assert.ok(game.contexts.every(context => context.profileID === expectedProfile));
    for (const context of game.contexts) {
      assert.equal(context.routes[0].status, "pending");
      assert.equal(context.routes[1].precisionKey, "regionalReference");
      assert.equal(context.routes[1].regionID, "sa-east-1");
    }
  }
});

test("new editorial art has valid hashes, dimensions and identical native copies", async () => {
  const manifest = JSON.parse(await readFile(new URL("../catalog/artwork-manifest.json", import.meta.url)));
  const names = {
    "dead-by-daylight": "DeadByDaylight",
    "for-honor": "ForHonor",
    "borderlands-3": "Borderlands3",
    "new-world": "NewWorld",
    "squid-game-unleashed": "SquidGameUnleashed",
    "warhammer-darktide": "WarhammerDarktide",
    "marvel-snap": "MarvelSnap",
    "the-outlast-trials": "TheOutlastTrials",
    "tribes-of-midgard": "TribesOfMidgard",
    "crossfar": "Crossfar",
    "lost-rift": "LostRift",
    "star-wars-hunters": "StarWarsHunters",
    "rematch": "Rematch",
    "predecessor": "Predecessor",
    "super-mega-baseball-4": "SuperMegaBaseball4",
    "marauders": "Marauders",
    "legacy-steel-and-sorcery": "LegacySteelAndSorcery",
    "ninjala": "Ninjala",
    "roller-champions": "RollerChampions",
    "ghost-recon-breakpoint": "GhostReconBreakpoint",
    "dark-alliance": "DarkAlliance",
    "wolcen-lords-of-mayhem": "WolcenLordsOfMayhem",
    "streamline": "Streamline",
    "tacticool": "Tacticool",
    "ghost-war": "GhostWar",
    "overwatch-2": "Overwatch2"
  };
  for (const [id, name] of Object.entries(names)) {
    const item = manifest.items.find(item => item.gameID === id);
    assert.ok(item, `Manifest item missing: ${id}`);
    const bytes = await readFile(new URL(`../catalog/${item.path}`, import.meta.url));
    assert.equal(createHash("sha256").update(bytes).digest("hex"), item.sha256);
    assert.equal(bytes.subarray(0, 8).toString("hex"), "89504e470d0a1a0a");
    assert.equal(bytes.readUInt32BE(16), item.width);
    assert.equal(bytes.readUInt32BE(20), item.height);
    for (const path of [
      `Sources/NolaggyApp/Assets.xcassets/Game${name}.imageset/${id}.png`,
      `design-system/assets/games/${id}.png`,
      `android/app/src/main/res/drawable/game_${id.replaceAll("-", "_")}.png`
    ]) assert.deepEqual(await readFile(new URL(`../../${path}`, import.meta.url)), bytes);
  }
});
