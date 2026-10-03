import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import { buildCandidateCatalog, buildCanonicalCatalog } from "../catalog/catalog-v3.canonical.js";

test("expansion has 26 unique games and preserves existing contexts", async () => {
  const manifest = JSON.parse(await readFile(new URL("../catalog/artwork-manifest.json", import.meta.url)));
  const candidate = buildCandidateCatalog(manifest);
  const persisted = JSON.parse(await readFile(new URL("../catalog/catalog-v3.candidate.json", import.meta.url)));
  assert.deepEqual(persisted, candidate);
  assert.equal(candidate.games.length, 26);
  assert.equal(new Set(candidate.games.map(game => game.id)).size, 26);
  assert.deepEqual(candidate.games.slice(0, 22), buildCanonicalCatalog().games);
  const platforms = {
    "dead-by-daylight": ["playstation", "xbox", "pc", "nintendo"],
    "for-honor": ["playstation", "xbox", "pc"],
    "borderlands-3": ["playstation", "xbox", "pc", "nintendo"],
    "new-world": ["playstation", "xbox", "pc"]
  };
  for (const game of candidate.games.slice(22)) {
    assert.deepEqual(game.contexts.flatMap(context => context.platforms), platforms[game.id]);
    assert.ok(game.contexts.every(context => context.profileID === "CASUAL_REALTIME"));
    for (const context of game.contexts) {
      assert.equal(context.routes[0].status, "pending");
      assert.equal(context.routes[1].precisionKey, "regionalReference");
      assert.equal(context.routes[1].regionID, "sa-east-1");
    }
  }
});

test("new editorial art has valid hashes, dimensions and identical native copies", async () => {
  const manifest = JSON.parse(await readFile(new URL("../catalog/artwork-manifest.json", import.meta.url)));
  const names = { "dead-by-daylight": "DeadByDaylight", "for-honor": "ForHonor", "borderlands-3": "Borderlands3", "new-world": "NewWorld" };
  for (const [id, name] of Object.entries(names)) {
    const item = manifest.items.find(item => item.gameID === id);
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
