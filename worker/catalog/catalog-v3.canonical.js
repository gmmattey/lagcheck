import artworkManifest from "./artwork-manifest.json" with { type: "json" };

// Fonte canônica do schema 3. Não é um envelope e não pode ser servido ao app
// antes de passar pelo assinador externo. Toda rota própria começa pendente até
// ter host, codec e evidência validados; a AWS mantém cada título mensurável.
const artwork = {
  fortnite: ["fortnite.jpg", "4e3faa99dbf7472eaa4da27d2009b6780b995b629fda89433407d1ccacb07aee"],
  "call-of-duty-mobile": ["codm.jpg", "2bb77542b922bdb25a058dea2c1b21179b6619aef6ad2265fbacf3ffe35e9956"],
  "free-fire": ["freefire.jpg", "103ffe79457e16c41accf2101fcf2bcc4bd2d2b85e1d6c80d784684110517130"],
  "pubg-mobile": ["pubg.jpg", "5097efdef788c1eb0c8fc2001b19d1b0b010d26f38e79e1180d815628ca852a3"],
  "brawl-stars": ["brawlstars.jpg", "415a3b42bdeb902a7bc200216a3fed088143b0e41eb58400ec8811bc1811a357"],
  "wild-rift": ["wildrift.jpg", "3b619530f0f18505ce41b55e5b6ca2d0db5cbd7bc1464df9475e3d974e92fed2"],
  roblox: ["roblox.jpg", "6702b9ee977358dcb1a342d7df1559e1004b8efb583859a41a98ae9b909f1adc"],
  minecraft: ["minecraft.jpg", "007d90a546786e95248f9eab54792f00e3eae314be20f22eb260f531be062a8f"],
  "apex-legends": ["apexlegends.jpg", "926453d9d8f76235e8fb1e051dec1706f9846ffe5bafce9f6c3be1e418250933"],
  "blood-strike": ["bloodstrike.jpg", "bba52776478797f67b7ec444cea6fd961ec74c1ffaab709d108c1397d51ab799"],
  cs2: ["cs2.jpg", "46086f9ef16baa12ca1d69e0c12425afc78a578e74d63c81420c9eb8d7802799"],
  dota2: ["dota2.jpg", "885cf7c733d6008681b5c255b7e7ea46ad1adf64621cf42309e162b09d102c5f"],
  eafc: ["eafc.jpg", "75a365f296d43180a2fb2538f0e1e3af2bc3bb16962a0b12359bc071f3431f0d"],
  "league-of-legends": ["leagueoflegends.jpg", "d35fb3c48123299496f9cabdab601441c8f1d42ea1668b1f4173b283ec3fcd91"],
  palworld: ["palworld.jpg", "068cf1637e7f87cce8ac15853b7e641ce6917fe9c2ad08baf582363b31c0f6e7"],
  "rainbow-six": ["rainbowsix.jpg", "fec730855eeb13931d1ef2eda597444e7551a19bc87757ab83df6439e62e5026"],
  "rocket-league": ["rocketleague.jpg", "a747138ec9410e42d6cc619a7064a6476203e73a755819aaf1ce534243559abb"],
  rust: ["rust.jpg", "8960f0add7cecc4a4c2103f1100b649cbd32854847c5953fcd11cebb74c5dbde"],
  valorant: ["valorant.jpg", "51642b7cc97e644473df17fa66dee563b796ce8416731310d08a3ea5bc0e9039"],
  warzone: ["warzone.jpg", "9523eed8e2abd4fdbf05ac5d4e8d971cee31ef75815b8a659d0ee78d2e833f09"],
  "rainbow-six-mobile": ["rainbow-six-mobile.png", "beb68f31bd2311c77ea077a1dd75e58937ef59729fed90086bee2f38ea980f77"],
  "rocket-league-sideswipe": ["rocket-league-sideswipe.png", "6cb85405784ae1bdfd459b3e5503540392a7025bba2e5f4807510dffc278dfda"]
};

const establishedGames = [
  ["fortnite", "Fortnite", ["iphone", "playstation", "xbox", "pc", "nintendo"], "BATTLE_ROYALE_COMPETITIVE"],
  ["call-of-duty-mobile", "Call of Duty: Mobile", ["iphone"], "BATTLE_ROYALE_COMPETITIVE"],
  ["free-fire", "Free Fire", ["iphone"], "BATTLE_ROYALE_COMPETITIVE"],
  ["pubg-mobile", "PUBG MOBILE", ["iphone"], "BATTLE_ROYALE_COMPETITIVE"],
  ["brawl-stars", "Brawl Stars", ["iphone"], "MOBILE_REALTIME"],
  ["wild-rift", "League of Legends: Wild Rift", ["iphone"], "MOBILE_REALTIME"],
  ["roblox", "Roblox", ["iphone", "playstation", "xbox", "pc"], "CASUAL_REALTIME"],
  ["minecraft", "Minecraft", ["iphone", "playstation", "xbox", "pc", "nintendo"], "CASUAL_REALTIME"],
  ["apex-legends", "Apex Legends", ["playstation", "xbox", "pc", "nintendo"], "BATTLE_ROYALE_COMPETITIVE"],
  ["blood-strike", "Blood Strike", ["iphone", "pc"], "BATTLE_ROYALE_COMPETITIVE"],
  ["cs2", "Counter-Strike 2", ["pc"], "BATTLE_ROYALE_COMPETITIVE"],
  ["dota2", "Dota 2", ["pc"], "MOBILE_REALTIME"],
  ["eafc", "EA Sports FC", ["iphone", "playstation", "xbox", "pc", "nintendo"], "CASUAL_REALTIME"],
  ["league-of-legends", "League of Legends", ["pc"], "MOBILE_REALTIME"],
  ["palworld", "Palworld", ["xbox", "pc"], "CASUAL_REALTIME"],
  ["rainbow-six", "Rainbow Six Siege", ["playstation", "xbox", "pc"], "BATTLE_ROYALE_COMPETITIVE"],
  ["rocket-league", "Rocket League", ["playstation", "xbox", "pc", "nintendo"], "CASUAL_REALTIME"],
  ["rust", "Rust", ["playstation", "xbox", "pc"], "CASUAL_REALTIME"],
  ["valorant", "VALORANT", ["playstation", "xbox", "pc"], "BATTLE_ROYALE_COMPETITIVE"],
  ["warzone", "Call of Duty: Warzone", ["playstation", "xbox", "pc"], "BATTLE_ROYALE_COMPETITIVE"],
  ["rainbow-six-mobile", "Rainbow Six Mobile", ["iphone"], "BATTLE_ROYALE_COMPETITIVE"],
  ["rocket-league-sideswipe", "Rocket League Sideswipe", ["iphone"], "CASUAL_REALTIME"]
];

const profileVersions = {
  BATTLE_ROYALE_COMPETITIVE: "pilot-2026.09.08.1",
  MOBILE_REALTIME: "mobile-realtime-2026.09.08.1",
  CASUAL_REALTIME: "casual-realtime-2026.09.08.1"
};

// Decisão 90: a referência é escolhida pela menor latência UDP observada,
// entre regiões assinadas; nunca pelo país, idioma ou posição neste array.
const globalProbeRegions = [
  ["sa-east-1", "São Paulo", "São Paulo", "São Paulo"],
  ["us-east-1", "Virgínia do Norte", "N. Virginia", "Virginia del Norte"],
  ["us-east-2", "Ohio", "Ohio", "Ohio"],
  ["us-west-1", "Norte da Califórnia", "N. California", "Norte de California"],
  ["us-west-2", "Oregon", "Oregon", "Oregón"],
  ["ca-central-1", "Canadá Central", "Central Canada", "Canadá Central"],
  ["eu-central-1", "Frankfurt", "Frankfurt", "Fráncfort"],
  ["eu-west-1", "Irlanda", "Ireland", "Irlanda"],
  ["eu-west-2", "Londres", "London", "Londres"],
  ["eu-west-3", "Paris", "Paris", "París"],
  ["eu-north-1", "Estocolmo", "Stockholm", "Estocolmo"],
  ["eu-south-1", "Milão", "Milan", "Milán"],
  ["ap-northeast-1", "Tóquio", "Tokyo", "Tokio"],
  ["ap-northeast-2", "Seul", "Seoul", "Seúl"],
  ["ap-northeast-3", "Osaka", "Osaka", "Osaka"],
  ["ap-southeast-1", "Cingapura", "Singapore", "Singapur"],
  ["ap-southeast-2", "Sydney", "Sydney", "Sídney"],
  ["ap-south-1", "Mumbai", "Mumbai", "Mumbai"],
  ["ap-east-1", "Hong Kong", "Hong Kong", "Hong Kong"],
  ["me-south-1", "Bahrein", "Bahrain", "Baréin"],
  ["af-south-1", "Cidade do Cabo", "Cape Town", "Ciudad del Cabo"]
];

function routesFor(gameID, platform) {
  const key = `${gameID}-${platform}`;
  return [
    {
      id: `${key}-owned`, kind: "gameOwned", status: "pending", regionID: `${key}-br`,
      strategy: "dedicatedServer", confidence: "high", precisionKey: "dedicatedServer"
    },
    {
      id: `${key}-aws`, kind: "awsFallback", status: "active", regionID: "sa-east-1",
      strategy: "genericRegion", confidence: "medium", precisionKey: "regionalReference"
    }
  ];
}

// Decisão 89: estas expansões são parte da fonte canônica a ser assinada.
export const catalogExpansionGames = [
  ["dead-by-daylight", "Dead by Daylight", ["playstation", "xbox", "pc", "nintendo"], "CASUAL_REALTIME"],
  ["for-honor", "For Honor", ["playstation", "xbox", "pc"], "CASUAL_REALTIME"],
  ["borderlands-3", "Borderlands 3", ["playstation", "xbox", "pc", "nintendo"], "CASUAL_REALTIME"],
  ["new-world", "New World: Aeternum", ["playstation", "xbox", "pc"], "CASUAL_REALTIME"],
  ["squid-game-unleashed", "Squid Game: Unleashed", ["iphone", "playstation", "xbox", "pc"], "CASUAL_REALTIME"],
  ["warhammer-darktide", "Warhammer 40,000: Darktide", ["playstation", "xbox", "pc"], "CASUAL_REALTIME"],
  ["marvel-snap", "MARVEL SNAP", ["iphone", "pc"], "MOBILE_REALTIME"],
  ["the-outlast-trials", "The Outlast Trials", ["playstation", "xbox", "pc"], "CASUAL_REALTIME"],
  ["tribes-of-midgard", "Tribes of Midgard", ["playstation", "xbox", "pc", "nintendo"], "CASUAL_REALTIME"],
  ["crossfar", "Crossfar", ["pc"], "BATTLE_ROYALE_COMPETITIVE"],
  ["lost-rift", "Lost Rift", ["pc"], "BATTLE_ROYALE_COMPETITIVE"],
  ["star-wars-hunters", "Star Wars: Hunters", ["iphone", "nintendo"], "MOBILE_REALTIME"],
  ["rematch", "Rematch", ["playstation", "xbox", "pc"], "CASUAL_REALTIME"],
  ["predecessor", "Predecessor", ["playstation", "xbox", "pc"], "MOBILE_REALTIME"],
  ["super-mega-baseball-4", "Super Mega Baseball 4", ["playstation", "xbox", "pc", "nintendo"], "CASUAL_REALTIME"],
  ["marauders", "Marauders", ["pc"], "BATTLE_ROYALE_COMPETITIVE"],
  ["legacy-steel-and-sorcery", "Legacy: Steel & Sorcery", ["pc"], "CASUAL_REALTIME"],
  ["ninjala", "Ninjala", ["nintendo"], "CASUAL_REALTIME"],
  ["roller-champions", "Roller Champions", ["playstation", "xbox", "pc", "nintendo"], "CASUAL_REALTIME"],
  ["ghost-recon-breakpoint", "Ghost Recon Breakpoint", ["playstation", "xbox", "pc"], "CASUAL_REALTIME"],
  ["dark-alliance", "Dungeons & Dragons: Dark Alliance", ["playstation", "xbox", "pc"], "CASUAL_REALTIME"],
  ["wolcen-lords-of-mayhem", "Wolcen: Lords of Mayhem", ["playstation", "xbox", "pc"], "CASUAL_REALTIME"],
  ["streamline", "Streamline", ["pc"], "CASUAL_REALTIME"],
  ["tacticool", "Tacticool", ["iphone", "pc"], "BATTLE_ROYALE_COMPETITIVE"],
  ["ghost-war", "Ghost War", ["iphone"], "MOBILE_REALTIME"],
  ["overwatch-2", "Overwatch 2", ["playstation", "xbox", "pc", "nintendo"], "BATTLE_ROYALE_COMPETITIVE"]
];

const expansionArtwork = new Map(artworkManifest.items.map(item => [item.gameID, item]));
const publishedGames = [...establishedGames, ...catalogExpansionGames];

function artworkFor(gameID) {
  if (artwork[gameID]) return artwork[gameID];
  const item = expansionArtwork.get(gameID);
  if (!item) throw new Error(`Missing artwork: ${gameID}`);
  return [item.path.split("/").at(-1), item.sha256];
}

export function buildCanonicalCatalog() {
  return {
    schemaVersion: 3,
    catalogVersion: "catalog-v3-2026.10.17.3",
    assetBaseURL: "https://nolaggy-deep-check.buildealabs.workers.dev/",
    profiles: Object.entries(profileVersions).map(([id, ruleVersion]) => ({ id, ruleVersion })),
    regions: globalProbeRegions.map(([id, ptBR, en, es]) => ({
      id, label: { "pt-BR": ptBR, en, es },
      probe: { host: `gamelift-ping.${id}.api.aws`, port: 7770, protocolKind: "gameLiftPing" }
    })),
    games: publishedGames.map(([id, name, platforms, profileID]) => {
      const [filename, sha256] = artworkFor(id);
      return {
        id, name,
        artwork: { path: `artwork/games/${filename}`, sha256 },
        rating: { status: "pendingVerification", sourceName: "Aguardando fonte editorial verificável" },
        contexts: platforms.map(platform => ({
          market: "BR", platforms: [platform], profileID, availability: "available", measurement: null,
          routes: routesFor(id, platform)
        }))
      };
    })
  };
}
