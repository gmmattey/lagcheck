import fs from 'node:fs';
import path from 'node:path';

const ROOT_DIR = process.cwd();
const WEB_DIR = path.join(ROOT_DIR, 'web');
const APP_STORE_URL = "https://apps.apple.com/br/app/lagcheck-teste-de-ping-gamer/id6818706960";
const LINKA_APP_STORE_URL = "https://apps.apple.com/app/id6808479321";

const GAMES = [
  { slug: "fortnite", name: "Fortnite", file: "fortnite", platforms: "iPhone · PC · PlayStation · Xbox · Switch", infra: "fort" },
  { slug: "free-fire", name: "Free Fire", file: "freefire", platforms: "iPhone", infra: "priv" },
  { slug: "cod-mobile", name: "COD Mobile", file: "codm", platforms: "iPhone", infra: "priv" },
  { slug: "valorant", name: "Valorant", file: "valorant", platforms: "PC · PlayStation · Xbox", infra: "priv" },
  { slug: "counter-strike-2", name: "Counter-Strike 2", file: "cs2", platforms: "PC", infra: "ded" },
  { slug: "apex-legends", name: "Apex Legends", file: "apexlegends", platforms: "PC · PlayStation · Xbox · Switch", infra: "priv" },
  { slug: "league-of-legends", name: "League of Legends", file: "leagueoflegends", platforms: "PC", infra: "priv" },
  { slug: "wild-rift", name: "Wild Rift", file: "wildrift", platforms: "iPhone", infra: "priv" },
  { slug: "rocket-league", name: "Rocket League", file: "rocketleague", platforms: "PC · PlayStation · Xbox · Switch", infra: "priv" },
  { slug: "roblox", name: "Roblox", file: "roblox", platforms: "iPhone · PC · PlayStation · Xbox", infra: "rbx" },
  { slug: "minecraft", name: "Minecraft", file: "minecraft", platforms: "iPhone · PC · PlayStation · Xbox · Switch", infra: "ded" },
  { slug: "brawl-stars", name: "Brawl Stars", file: "brawlstars", platforms: "iPhone", infra: "priv" },
  { slug: "warzone", name: "Warzone", file: "warzone", platforms: "PC · PlayStation · Xbox", infra: "priv" },
  { slug: "pubg-mobile", name: "PUBG Mobile", file: "pubg", platforms: "iPhone", infra: "priv" },
  { slug: "blood-strike", name: "Blood Strike", file: "bloodstrike", platforms: "iPhone · PC", infra: "priv" },
  { slug: "dota-2", name: "Dota 2", file: "dota2", platforms: "PC", infra: "priv" },
  { slug: "ea-sports-fc", name: "EA Sports FC", file: "eafc", platforms: "iPhone · PC · PlayStation · Xbox · Switch", infra: "priv" },
  { slug: "palworld", name: "Palworld", file: "palworld", platforms: "PC · Xbox", infra: "ded" },
  { slug: "rainbow-six-siege", name: "Rainbow Six Siege", file: "rainbowsix", platforms: "PC · PlayStation · Xbox", infra: "priv" },
  { slug: "rust", name: "Rust", file: "rust", platforms: "PC · PlayStation · Xbox", infra: "ded" }
];

function getRouteText(infra) {
  const base = "O Lagcheck mede a rota UDP até o beacon AWS GameLift em São Paulo (sa-east-1).";
  if (infra === "fort") return "O Fortnite tem crossplay e usa a mesma infraestrutura em nuvem em várias plataformas. " + base;
  if (infra === "ded") return "Neste jogo o servidor costuma ser escolhido pelo operador de cada mundo ou servidor, sem destino fixo para teste. " + base;
  if (infra === "rbx") return "No Roblox a instância depende da experiência e da sessão, sem destino fixo para teste. " + base;
  return "O matchmaking deste jogo é privado e a distribuidora não publica destino de teste. " + base;
}

const COMMON_CSS = `
body {
  margin: 0;
  background: oklch(0.12 0.01 260);
  color: oklch(0.955 0.006 260);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
}
a { color: inherit; text-decoration: none; }
a:hover { color: oklch(0.78 0.12 299); }
* { box-sizing: border-box; }
@keyframes fl { 0%, 100% { transform: translateX(-50%) translateY(0); } 50% { transform: translateX(-50%) translateY(-18px); } }
@keyframes fll { 0%, 100% { transform: rotate(-6deg) translateY(0); } 50% { transform: rotate(-8deg) translateY(14px); } }
@keyframes flr { 0%, 100% { transform: rotate(6deg) translateY(0); } 50% { transform: rotate(8deg) translateY(-14px); } }
@keyframes ring { 0% { transform: translate(-50%, -50%) scale(0.3); opacity: 0.7; } 100% { transform: translate(-50%, -50%) scale(1.6); opacity: 0; } }
@keyframes mq { to { transform: translateX(-50%); } }
@keyframes gx { 0% { background-position: 0% 50%; } 100% { background-position: 200% 50%; } }
@keyframes glow { 0%, 100% { box-shadow: 0 0 0 0 oklch(0.585 0.214 299 / 0.5); } 50% { box-shadow: 0 0 0 14px oklch(0.585 0.214 299 / 0); } }
@keyframes blink { 50% { opacity: 0.25; } }
@keyframes rise { from { opacity: 0; transform: translateY(30px); } to { opacity: 1; transform: none; } }
@keyframes kb { to { transform: scale(1.12); } }
[data-rv] { opacity: 0; transform: translateY(46px) scale(0.97); transition: opacity 0.8s cubic-bezier(0.2, 0, 0, 1), transform 0.8s cubic-bezier(0.2, 0, 0, 1); }
[data-rv].in { opacity: 1; transform: none; }
[data-rv]:nth-child(2) { transition-delay: 0.12s; }
[data-rv]:nth-child(3) { transition-delay: 0.24s; }
.hi { animation: rise 0.9s cubic-bezier(0.2, 0, 0, 1) both; }
@media (prefers-reduced-motion: reduce) {
  * { animation: none !important; }
  [data-rv] { opacity: 1; transform: none; }
}
::-webkit-scrollbar { display: none; }
.btn-appstore {
  display: inline-block;
  transition: transform 0.2s, opacity 0.2s;
}
.btn-appstore:hover {
  transform: translateY(-2px);
  opacity: 0.95;
}
`;

const TELEMETRY_AND_CONVERSION_SCRIPT = `
<script>
(function() {
  // Observador de animações de scroll
  var io = new IntersectionObserver(function(entries) {
    entries.forEach(function(e) {
      if (e.isIntersecting) {
        e.target.classList.add('in');
        io.unobserve(e.target);
      }
    });
  }, { threshold: 0.12 });
  function scan() {
    document.querySelectorAll('[data-rv]:not(.in)').forEach(function(el) { io.observe(el); });
  }
  scan();
  setInterval(scan, 800);

  // 1. Telemetria anônima de visitas para o informe diário do Discord
  try {
    var visitPayload = JSON.stringify({ path: window.location.pathname, ref: document.referrer || undefined });
    if (navigator.sendBeacon) {
      navigator.sendBeacon('/v1/visit', visitPayload);
    } else {
      fetch('/v1/visit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: visitPayload,
        keepalive: true
      }).catch(function() {});
    }
  } catch(e) {}

  // 2. Registro de CONVERSÃO ao clicar para baixar na App Store (dispara relatório Discord)
  document.addEventListener('click', function(e) {
    var target = e.target.closest('a[data-track-conversion="appstore"]');
    if (!target) return;

    try {
      var convPayload = JSON.stringify({
        email: 'appstore_download@click.local',
        platform: 'ios',
        source: new URLSearchParams(location.search).get('utm_source') || 'web_download',
        utm: Object.fromEntries(new URLSearchParams(location.search).entries()),
        createdAt: new Date().toISOString()
      });

      if (navigator.sendBeacon) {
        navigator.sendBeacon('/v1/waitlist', convPayload);
      } else {
        fetch('/v1/waitlist', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: convPayload,
          keepalive: true
        }).catch(function() {});
      }
    } catch(err) {}
  });
})();
</script>
`;

function buildHeader(activePage = '') {
  return `
<header style="position:sticky;top:0;z-index:20;display:flex;align-items:center;justify-content:space-between;padding:14px max(22px,calc((100% - 1200px)/2));background:oklch(0.12 0.01 260 / 0.82);backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);border-bottom:1px solid oklch(0.25 0.012 260)">
  <a href="/" aria-label="Lagcheck Home"><img src="/assets/lagcheck-wordmark-light.svg" alt="Lagcheck" style="width:124px;display:block"></a>
  <nav style="display:flex;gap:24px;font-size:13px;color:oklch(0.75 0.014 260)">
    <a href="/jogos/" style="${activePage === 'jogos' ? 'color:oklch(0.955 0.006 260);font-weight:700;' : ''}">Jogos</a>
    <a href="/#casos">Casos de uso</a>
    <a href="/#concorrentes">Comparativo</a>
    <a href="/#combo">Linka</a>
    <a href="/#como">Como funciona</a>
    <a href="/#veredito">Veredito</a>
    <a href="/#faq">Dúvidas</a>
  </nav>
  <a href="${APP_STORE_URL}" target="_blank" rel="noopener noreferrer" data-track-conversion="appstore" style="padding:9px 18px;border-radius:999px;background:oklch(0.585 0.214 299);color:oklch(0.98 0 0);font-size:13px;font-weight:700">Baixar na App Store</a>
</header>
`;
}

function buildFooter() {
  return `
<footer style="display:flex;flex-wrap:wrap;gap:20px;align-items:center;justify-content:space-between;max-width:1200px;margin:auto;padding:36px 22px;font:11px ui-monospace,monospace;color:oklch(0.675 0.014 260);border-top:1px solid oklch(0.2 0.012 260)">
  <a href="/" aria-label="Lagcheck Home"><img src="/assets/lagcheck-wordmark-light.svg" alt="Lagcheck" style="width:110px"></a>
  <nav style="display:flex;gap:18px">
    <a href="${APP_STORE_URL}" target="_blank" rel="noopener noreferrer" data-track-conversion="appstore">Baixar o Lagcheck</a>
    <a href="${LINKA_APP_STORE_URL}" target="_blank" rel="noopener noreferrer">Baixar o Linka</a>
    <a href="/jogos/">Jogos</a>
    <a href="/support/">Suporte</a>
    <a href="/privacy/">Privacidade</a>
  </nav>
</footer>
`;
}

// 1. GERAR A HOME (web/index.html)
function generateHome() {
  const compRows = [
    { a: 'App', b: 'Foco principal', c: 'Resposta que entrega', d: 'Modelo', bg: 'oklch(0.2 0.02 260)', fg: 'oklch(0.675 0.014 260)', fg2: 'oklch(0.675 0.014 260)' },
    { a: 'Lagcheck', b: 'Qualidade da rota para jogar', c: 'Veredito: pronto para ranked ou não', d: 'Grátis no iPhone', bg: 'oklch(0.2 0.06 299)', fg: 'oklch(0.9 0.1 299)', fg2: 'oklch(0.8 0.012 260)', hl: true },
    { a: 'Speedtest (Ookla)', b: 'Velocidade de banda', c: 'Download, upload e ping pontual', d: 'Teste de velocidade', bg: 'oklch(0.12 0.01 260)', fg: 'oklch(0.955 0.006 260)', fg2: 'oklch(0.8 0.012 260)' },
    { a: 'Fast.com', b: 'Velocidade de download', c: 'Quanto de banda você tem agora', d: 'Teste de velocidade', bg: 'oklch(0.12 0.01 260)', fg: 'oklch(0.955 0.006 260)', fg2: 'oklch(0.8 0.012 260)' },
    { a: 'ExitLag', b: 'Otimização de rota', c: 'Tenta melhorar o caminho até o servidor', d: 'Assinatura paga', bg: 'oklch(0.12 0.01 260)', fg: 'oklch(0.955 0.006 260)', fg2: 'oklch(0.8 0.012 260)' },
    { a: 'NoPing', b: 'Otimização de rota', c: 'Tenta reduzir ping e instabilidade', d: 'Assinatura paga', bg: 'oklch(0.12 0.01 260)', fg: 'oklch(0.955 0.006 260)', fg2: 'oklch(0.8 0.012 260)' }
  ];

  const marqueeGames = [...GAMES.slice(0, 12), ...GAMES.slice(0, 12)];

  const marqueeHtml = marqueeGames.map(g => `
    <a href="/jogos/${g.slug}/" style="flex:0 0 auto;width:196px;display:block">
      <div style="width:196px;height:196px;border-radius:22px;overflow:hidden;transition:transform .3s;background:oklch(0.2 0.012 260);box-shadow:0 14px 30px #0006">
        <img src="/assets/games/${g.file}.jpg" alt="${g.name}" style="width:100%;height:100%;object-fit:cover;display:block">
      </div>
      <div style="margin-top:12px;font-weight:700;font-size:15px;letter-spacing:-.01em">${g.name}</div>
      <div style="margin-top:3px;font:11px ui-monospace,monospace;color:oklch(0.675 0.014 260)">Pronto para check</div>
    </a>
  `).join('');

  const steps = [
    { n: '01', t: 'Escolha o jogo', d: 'Comece pelo jogo que você vai abrir agora.', bg: 'linear-gradient(160deg,oklch(0.28 0.12 299),oklch(0.18 0.04 280))' },
    { n: '02', t: 'Faça o check', d: 'Em cerca de 25–35 segundos, observamos a rota em repouso e sob carga.', bg: 'linear-gradient(160deg,oklch(0.24 0.09 270),oklch(0.17 0.03 260))' },
    { n: '03', t: 'Receba o veredito', d: 'Pronto para Ranked, condições instáveis ou um sinal honesto para evitar ranked.', bg: 'linear-gradient(160deg,oklch(0.3 0.1 330),oklch(0.18 0.04 290))' }
  ];

  const stepsHtml = steps.map(s => `
    <article data-rv="1" style="min-height:340px;padding:30px;border-radius:30px;background:${s.bg};display:flex;flex-direction:column;justify-content:space-between;overflow:hidden">
      <span style="font:12px ui-monospace,monospace;letter-spacing:.1em;color:oklch(0.85 0.08 299)">${s.n}</span>
      <div>
        <h3 style="margin:0;font:850 34px/1 ui-rounded,system-ui,sans-serif;letter-spacing:-.05em">${s.t}</h3>
        <p style="margin:12px 0 0;font-size:16px;line-height:1.45;color:oklch(0.85 0.01 260)">${s.d}</p>
      </div>
    </article>
  `).join('');

  const uses = [
    { n: '01', t: 'Ranked' },
    { n: '02', t: 'Casual' },
    { n: '03', t: 'Party / Discord' },
    { n: '04', t: 'Streaming + jogo' }
  ];

  const usesHtml = uses.map(u => `
    <article data-rv="1" style="min-height:190px;padding:26px;border-radius:26px;background:oklch(0.2 0.012 260);border:1px solid oklch(0.3 0.014 260);display:flex;flex-direction:column;justify-content:space-between">
      <span style="font:12px ui-monospace,monospace;color:oklch(0.78 0.12 299)">${u.n}</span>
      <h3 style="margin:0;font:850 28px/1 ui-rounded,system-ui,sans-serif;letter-spacing:-.05em">${u.t}</h3>
    </article>
  `).join('');

  const compTableHtml = compRows.map(r => `
    <div style="padding:18px 20px;background:${r.bg};font:850 17px ui-rounded,system-ui,sans-serif;letter-spacing:-.03em;color:${r.fg}">${r.a}</div>
    <div style="padding:18px 20px;background:${r.bg};font-size:14px;line-height:1.4;color:${r.fg2}">${r.b}</div>
    <div style="padding:18px 20px;background:${r.bg};font-size:14px;line-height:1.4;color:${r.fg2}">${r.c}</div>
    <div style="padding:18px 20px;background:${r.bg};font-size:14px;line-height:1.4;color:${r.fg2}">${r.d}</div>
  `).join('');

  const awsFacts = [
    { k: 'Protocolo', v: 'UDP real' },
    { k: 'Destino', v: 'AWS GameLift · sa-east-1' },
    { k: 'Regiões', v: '21 no mundo' },
    { k: 'Fase 2', v: 'Medição sob carga' }
  ];

  const awsFactsHtml = awsFacts.map(f => `
    <div style="display:flex;justify-content:space-between;gap:16px;padding:14px 16px;border-radius:14px;background:oklch(0.12 0.01 260 / 0.7);border:1px solid oklch(0.3 0.014 260)">
      <span style="color:oklch(0.675 0.014 260)">${f.k}</span>
      <b style="font-weight:600;text-align:right">${f.v}</b>
    </div>
  `).join('');

  const faq = [
    { q: 'Por que estou com lag no jogo?', a: 'Velocidade pode estar boa e a rota ainda oscilar, perder pacotes ou piorar sob carga. É isso que um check focado em jogo separa.' },
    { q: 'Como saber se posso jogar ranked?', a: 'Faça um check antes da fila. O veredito não promete zero lag: indica quando os sinais observados pedem cautela.' },
    { q: 'Speedtest mostra lag de verdade?', a: 'Ajuda a entender a conexão, mas não substitui medir estabilidade, jitter, perda e comportamento sob pressão.' }
  ];

  const faqHtml = faq.map(f => `
    <article data-rv="1" style="padding:28px;border-radius:24px;background:oklch(0.2 0.012 260)">
      <h3 style="margin:0;font:800 20px/1.1 ui-rounded,system-ui,sans-serif;letter-spacing:-.04em">${f.q}</h3>
      <p style="margin:12px 0 0;color:oklch(0.72 0.014 260);font-size:15px;line-height:1.5">${f.a}</p>
    </article>
  `).join('');

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Lagcheck — Teste de lag: sua conexão aguenta o ranked?</title>
  <meta name="description" content="Meça latência, jitter e perda de pacotes antes do ranked e saiba se sua conexão aguenta. Disponível na App Store para iPhone.">
  <meta name="robots" content="index,follow">
  <meta name="apple-itunes-app" content="app-id=6818706960">
  <link rel="canonical" href="https://lagcheck.signallq.com/">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
  <meta name="theme-color" content="#0B0D10">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="pt_BR">
  <meta property="og:site_name" content="Lagcheck">
  <meta property="og:title" content="Lagcheck — Teste de lag: sua conexão aguenta o ranked?">
  <meta property="og:description" content="Medição real de latência, jitter e perda antes de entrar na partida. Disponível na App Store.">
  <meta property="og:url" content="https://lagcheck.signallq.com/">
  <meta property="og:image" content="https://lagcheck.signallq.com/og.png">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:image:alt" content="Lagcheck: sua conexão está pronta para ranked?">
  <meta name="twitter:card" content="summary_large_image">
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "MobileApplication",
        "name": "Lagcheck: Teste de Ping Gamer",
        "operatingSystem": "iOS 17.0+",
        "applicationCategory": "UtilitiesApplication",
        "offers": { "@type": "Offer", "price": "0", "priceCurrency": "BRL" },
        "description": "App que diagnostica latência, jitter e perda de pacotes para jogos online antes do ranked.",
        "url": "${APP_STORE_URL}"
      },
      {
        "@type": "FAQPage",
        "mainEntity": [
          {
            "@type": "Question",
            "name": "Por que estou com lag no jogo?",
            "acceptedAnswer": { "@type": "Answer", "text": "Velocidade pode estar boa e a rota ainda oscilar, perder pacotes ou piorar sob carga." }
          },
          {
            "@type": "Question",
            "name": "Como saber se posso jogar ranked?",
            "acceptedAnswer": { "@type": "Answer", "text": "Faça um check antes da fila. O veredito indica quando os sinais observados pedem cautela." }
          },
          {
            "@type": "Question",
            "name": "Speedtest mostra lag de verdade?",
            "acceptedAnswer": { "@type": "Answer", "text": "Ele ajuda a entender a conexão, mas não substitui medir estabilidade, jitter, perda e comportamento sob pressão." }
          }
        ]
      }
    ]
  }
  </script>
  <style>${COMMON_CSS}</style>
</head>
<body>
<div style="min-width:320px;overflow:hidden">
  ${buildHeader()}

  <!-- HERO SECTION -->
  <section id="inicio" style="position:relative;padding:92px 22px 0;text-align:center;background:radial-gradient(ellipse 60% 50% at 50% 38%,oklch(0.3 0.13 299 / 0.45),transparent 70%)">
    <p class="hi" style="margin:0 0 18px;font:11px ui-monospace,Menlo,monospace;letter-spacing:.12em;text-transform:uppercase;color:oklch(0.78 0.12 299)">Disponível na App Store para iPhone</p>
    <h1 class="hi" style="animation-delay:.12s;margin:0 auto;max-width:900px;font:900 clamp(48px,8.6vw,112px)/.92 ui-rounded,'Arial Rounded MT Bold',system-ui,sans-serif;letter-spacing:-.06em;text-wrap:balance">
      Sua conexão está pronta para o <span style="background:linear-gradient(90deg,oklch(0.7 0.2 299),oklch(0.75 0.17 200),oklch(0.7 0.2 330),oklch(0.7 0.2 299));background-size:200% 100%;-webkit-background-clip:text;background-clip:text;color:transparent;animation:gx 4s linear infinite">ranked</span>?
    </h1>
    <p class="hi" style="animation-delay:.24s;margin:26px auto 0;max-width:560px;font-size:20px;line-height:1.4;color:oklch(0.75 0.014 260);letter-spacing:-.01em">
      O Lagcheck mede latência, jitter e perda de pacotes e diz se vale entrar na partida agora.
    </p>
    <div class="hi" style="animation-delay:.36s;gap:14px;align-items:center;flex-wrap:wrap;display:flex;justify-content:center;margin-top:34px">
      <a href="${APP_STORE_URL}" target="_blank" rel="noopener noreferrer" data-track-conversion="appstore" aria-label="Baixar na App Store" class="btn-appstore" style="display:inline-flex;gap:14px;align-items:center;text-decoration:none">
        <span style="display:inline-flex;gap:9px;align-items:center;padding:10px 16px;border-radius:999px;border:1px solid oklch(0.3 0.014 260);font:11px ui-monospace,monospace;color:oklch(0.75 0.014 260)">
          <i style="width:8px;height:8px;border-radius:50%;background:oklch(0.76 0.15 150);animation:blink 1.2s infinite;display:inline-block"></i>check em 25–35 s
        </span>
        <img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/pt-br?size=250x83" alt="Baixar na App Store" style="height:56px;display:block">
      </a>
    </div>

    <!-- MOCKUPS FLUTUANTES COM RADAR RINGS -->
    <div style="position:relative;height:clamp(420px,52vw,620px);margin:64px auto 0;max-width:900px;overflow:hidden">
      <div style="position:absolute;left:50%;top:260px;width:520px;height:520px;border-radius:50%;border:2px solid oklch(0.585 0.214 299);animation:ring 3.6s ease-out infinite"></div>
      <div style="position:absolute;left:50%;top:260px;width:520px;height:520px;border-radius:50%;border:2px solid oklch(0.585 0.214 299);animation:ring 3.6s ease-out 1.8s infinite"></div>
      <img src="/assets/app-games.webp" alt="Tela de jogos do Lagcheck" style="position:absolute;left:4%;top:60px;width:min(36%,300px);border-radius:34px;border:1px solid oklch(0.37 0.012 260);animation:fll 6s ease-in-out infinite;opacity:.7;box-shadow:0 38px 90px #0008">
      <img src="/assets/app-home.webp" alt="Tela inicial do Lagcheck" style="position:absolute;left:50%;top:0;width:min(42%,340px);animation:fl 5s ease-in-out infinite;border-radius:38px;border:1px solid oklch(0.4 0.012 260);box-shadow:0 38px 90px #000a;z-index:2">
      <img src="/assets/app-result.webp" alt="Tela de resultado de medição" style="position:absolute;right:4%;top:60px;width:min(36%,300px);border-radius:34px;border:1px solid oklch(0.37 0.012 260);animation:flr 7s ease-in-out infinite;opacity:.9;box-shadow:0 38px 90px #0008">
    </div>
  </section>

  <!-- MARQUEE INFINITO DE JOGOS -->
  <section id="jogos" style="padding:90px 0 20px;background:oklch(0.12 0.01 260)">
    <div style="max-width:1200px;margin:auto;padding:0 22px">
      <div style="display:flex;align-items:baseline;justify-content:space-between;gap:20px;flex-wrap:wrap">
        <h2 style="margin:0;font:850 clamp(30px,4vw,48px)/1 ui-rounded,system-ui,sans-serif;letter-spacing:-.05em">Escolha o jogo. Faça o check.</h2>
        <a href="/jogos/" style="font:11px ui-monospace,monospace;color:oklch(0.78 0.12 299);text-decoration:none">Ver todos os 20 jogos →</a>
      </div>
    </div>
    <div style="overflow:hidden;padding:34px 0 20px;-webkit-mask-image:linear-gradient(90deg,transparent,#000 6%,#000 94%,transparent);mask-image:linear-gradient(90deg,transparent,#000 6%,#000 94%,transparent)">
      <div style="display:flex;gap:16px;width:max-content;animation:mq 50s linear infinite" onmouseover="this.style.animationPlayState='paused'" onmouseout="this.style.animationPlayState='running'">
        ${marqueeHtml}
      </div>
    </div>
  </section>

  <!-- COMO FUNCIONA -->
  <section id="como" style="max-width:1200px;margin:auto;padding:90px 22px 0">
    <h2 style="margin:0 0 34px;font:850 clamp(30px,4vw,48px)/1 ui-rounded,system-ui,sans-serif;letter-spacing:-.05em;max-width:700px">Um check que respeita o que acontece na partida.</h2>
    <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px">
      ${stepsHtml}
    </div>
  </section>

  <!-- CASOS DE USO -->
  <section id="casos" style="max-width:1200px;margin:auto;padding:90px 22px 0">
    <p style="margin:0 0 13px;font:11px ui-monospace,monospace;letter-spacing:.1em;text-transform:uppercase;color:oklch(0.78 0.12 299)">O mesmo check, decisões diferentes</p>
    <h2 style="margin:0 0 34px;font:850 clamp(30px,4vw,48px)/1 ui-rounded,system-ui,sans-serif;letter-spacing:-.05em;max-width:700px">O ranked vem primeiro. O resto ganha contexto.</h2>
    <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px">
      ${usesHtml}
    </div>
  </section>

  <!-- VEREDITO -->
  <section id="veredito" style="max-width:1200px;margin:auto;padding:90px 22px 0">
    <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:16px">
      <article data-rv="1" style="padding:44px;border-radius:30px;background:oklch(0.2 0.012 260);border:1px solid oklch(0.3 0.014 260);display:flex;flex-direction:column;gap:22px">
        <span style="align-self:flex-start;padding:7px 12px;border-radius:999px;background:oklch(0.76 0.15 150 / 0.14);font:11px ui-monospace,monospace;color:oklch(0.76 0.15 150)">● veredito</span>
        <h3 style="margin:0;font:900 clamp(36px,5vw,64px)/.95 ui-rounded,system-ui,sans-serif;letter-spacing:-.06em">Pronto para Ranked</h3>
        <p style="margin:0;max-width:420px;font-size:17px;line-height:1.45;color:oklch(0.75 0.014 260)">O veredito vem primeiro. Os detalhes aparecem quando você precisa entender ou agir: latência, jitter, perda e rota.</p>
      </article>
      <article data-rv="1" style="padding:44px;border-radius:30px;background:oklch(0.2 0.012 260);border:1px solid oklch(0.3 0.014 260);display:flex;flex-direction:column;gap:22px">
        <span style="align-self:flex-start;padding:7px 12px;border-radius:999px;background:oklch(0.684 0.196 35 / 0.14);font:11px ui-monospace,monospace;color:oklch(0.75 0.17 35)">● honesto</span>
        <h3 style="margin:0;font:900 clamp(36px,5vw,64px)/.95 ui-rounded,system-ui,sans-serif;letter-spacing:-.06em">Condições instáveis</h3>
        <p style="margin:0;max-width:420px;font-size:17px;line-height:1.45;color:oklch(0.75 0.014 260)">Sem prometer zero lag. Quando os sinais pedem cautela, o app diz — e nunca preenche métricas que não mediu.</p>
      </article>
    </div>
    <p style="margin:34px 0 16px;max-width:680px;font-size:17px;line-height:1.5;color:oklch(0.72 0.014 260)">
      Se você quer testar ping no Fortnite, Free Fire ou COD Mobile, velocidade sozinha não mostra a história completa. O Lagcheck observa latência, jitter e perda de pacotes para responder se sua conexão está boa para ranked naquele momento.
    </p>
    <div data-rv="1" style="margin-top:16px;display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:1px;background:oklch(0.3 0.014 260);border:1px solid oklch(0.3 0.014 260);border-radius:30px;overflow:hidden">
      <div style="padding:34px;background:oklch(0.12 0.01 260)">
        <h4 style="margin:0;font:800 26px ui-rounded,system-ui,sans-serif;letter-spacing:-.05em">Speedtest</h4>
        <p style="margin:12px 0 18px;color:oklch(0.675 0.014 260);line-height:1.45">Mede a velocidade da conexão em um momento.</p>
        <div style="font:12px ui-monospace,monospace;line-height:2;color:oklch(0.8 0.01 260)">— Download<br>— Upload<br>— Ping pontual</div>
      </div>
      <div style="padding:34px;background:oklch(0.16 0.03 299)">
        <h4 style="margin:0;font:800 26px ui-rounded,system-ui,sans-serif;letter-spacing:-.05em">Lagcheck</h4>
        <p style="margin:12px 0 18px;color:oklch(0.8 0.02 299);line-height:1.45">Mede o que importa para jogar naquela rota.</p>
        <div style="font:12px ui-monospace,monospace;line-height:2">— Latência<br>— Jitter<br>— Perda de pacotes<br>— Comportamento sob carga</div>
      </div>
    </div>
  </section>

  <!-- COMPARATIVO COM CONCORRENTES -->
  <section id="concorrentes" style="max-width:1200px;margin:auto;padding:90px 22px 0">
    <p style="margin:0 0 13px;font:11px ui-monospace,monospace;letter-spacing:.1em;text-transform:uppercase;color:oklch(0.78 0.12 299)">Quadro comparativo</p>
    <h2 style="margin:0 0 14px;font:850 clamp(30px,4vw,48px)/1 ui-rounded,system-ui,sans-serif;letter-spacing:-.05em;max-width:760px">Cada app responde uma pergunta diferente.</h2>
    <p style="margin:0 0 30px;max-width:620px;font-size:16px;line-height:1.5;color:oklch(0.72 0.014 260)">
      Testes de velocidade medem banda. Otimizadores de rota vendem uma solução. O Lagcheck responde antes da fila: dá para jogar agora?
    </p>
    <div data-rv="1" style="overflow-x:auto;border-radius:26px;border:1px solid oklch(0.3 0.014 260)">
      <div style="min-width:760px;display:grid;grid-template-columns:1.1fr 1.3fr 1.5fr 1fr;gap:1px;background:oklch(0.3 0.014 260)">
        ${compTableHtml}
      </div>
    </div>
    <p style="margin:14px 0 0;font:11px ui-monospace,monospace;color:oklch(0.6 0.014 260)">
      Marcas citadas pertencem a seus respectivos donos. Comparação por foco de produto, não por desempenho.
    </p>
  </section>

  <!-- INFRAESTRUTURA AWS -->
  <section id="aws" style="max-width:1200px;margin:auto;padding:90px 22px 0">
    <div data-rv="1" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:40px;align-items:center;padding:clamp(28px,5vw,56px);border-radius:32px;background:linear-gradient(135deg,oklch(0.22 0.06 299),oklch(0.16 0.02 260))">
      <div>
        <p style="margin:0 0 13px;font:11px ui-monospace,monospace;letter-spacing:.1em;text-transform:uppercase;color:oklch(0.78 0.12 299)">Onde o ping é medido</p>
        <h2 style="margin:0;font:850 clamp(30px,4vw,48px)/1 ui-rounded,system-ui,sans-serif;letter-spacing:-.05em">Latência real até a infraestrutura AWS em São Paulo.</h2>
        <p style="margin:18px 0 0;font-size:16px;line-height:1.5;color:oklch(0.8 0.014 260)">
          Muitos jogos online rodam seus servidores na AWS. O Lagcheck envia pacotes UDP para os beacons de ping do AWS GameLift em 21 regiões e mede a rota real entre o seu iPhone e o datacenter regional, sem depender de ICMP.
        </p>
        <p style="margin:14px 0 0;font-size:14px;line-height:1.5;color:oklch(0.7 0.014 260)">
          Transparência: é uma rota de referência regional, não o servidor da sua próxima partida.
        </p>
      </div>
      <div style="display:grid;gap:10px;font:12px ui-monospace,monospace">
        ${awsFactsHtml}
      </div>
    </div>
  </section>

  <!-- FAQ -->
  <section id="faq" style="max-width:1200px;margin:auto;padding:90px 22px 0">
    <h2 style="margin:0 0 30px;font:850 clamp(30px,4vw,48px)/1 ui-rounded,system-ui,sans-serif;letter-spacing:-.05em">Dúvidas sobre lag</h2>
    <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px">
      ${faqHtml}
    </div>
  </section>

  <!-- COMBO LINKA + LAGCHECK -->
  <section id="combo" style="max-width:1200px;margin:90px auto 0;padding:0 22px">
    <div data-rv="1" style="padding:clamp(28px,5vw,60px);border-radius:34px;background:radial-gradient(ellipse 60% 90% at 50% 0%,oklch(0.3 0.12 299 / 0.5),transparent 70%),oklch(0.17 0.015 260);border:1px solid oklch(0.3 0.014 260);text-align:center">
      <p style="margin:0 0 13px;font:11px ui-monospace,monospace;letter-spacing:.1em;text-transform:uppercase;color:oklch(0.78 0.12 299)">A dobradinha</p>
      <h2 style="margin:0 auto;max-width:760px;font:900 clamp(34px,5vw,60px)/.95 ui-rounded,system-ui,sans-serif;letter-spacing:-.06em">
        Velocidade e estabilidade. O combo completo antes da fila.
      </h2>
      <div style="display:flex;align-items:stretch;justify-content:center;gap:16px;flex-wrap:wrap;margin-top:40px">
        <div style="flex:1 1 280px;max-width:380px;padding:30px;border-radius:26px;background:oklch(0.12 0.01 260);border:1px solid oklch(0.3 0.014 260);text-align:left">
          <img src="/assets/linka-icon.png" alt="Linka: Wi-Fi e Internet" style="width:56px;height:56px;border-radius:16px;object-fit:cover;display:block">
          <h3 style="margin:18px 0 0;font:850 30px ui-rounded,system-ui,sans-serif;letter-spacing:-.05em">Linka</h3>
          <p style="margin:10px 0 0;font-size:15px;line-height:1.45;color:oklch(0.75 0.014 260)">Teste de velocidade da sua internet. Saiba quanta banda você tem.</p>
          <a href="${LINKA_APP_STORE_URL}" target="_blank" rel="noopener noreferrer" style="display:inline-block;margin-top:20px;padding:12px 20px;border-radius:13px;background:oklch(0.2 0.03 260);border:1px solid oklch(0.4 0.014 260);color:#fff;font-weight:800;font-size:14px">Baixar o Linka na App Store →</a>
          <div style="margin-top:12px"><a href="https://linka-speedtest.web.app/" target="_blank" rel="noopener noreferrer" style="font:11px ui-monospace,monospace;color:oklch(0.675 0.014 260);text-decoration:underline">Ou testar velocidade na web</a></div>
        </div>
        <div style="align-self:center;font:900 44px ui-rounded,system-ui,sans-serif;color:oklch(0.585 0.214 299);animation:blink 1.6s infinite">+</div>
        <div style="flex:1 1 280px;max-width:380px;padding:30px;border-radius:26px;background:oklch(0.2 0.06 299);border:1px solid oklch(0.585 0.214 299 / 0.6);text-align:left">
          <img src="/assets/app-home.webp" alt="Lagcheck App" style="width:56px;height:56px;border-radius:16px;object-fit:cover;object-position:top">
          <h3 style="margin:18px 0 0;font:850 30px ui-rounded,system-ui,sans-serif;letter-spacing:-.05em">Lagcheck</h3>
          <p style="margin:10px 0 0;font-size:15px;line-height:1.45;color:oklch(0.85 0.02 299)">Veredito de lag para jogar. Saiba se a conexão aguenta o ranked agora.</p>
          <a href="${APP_STORE_URL}" target="_blank" rel="noopener noreferrer" data-track-conversion="appstore" style="display:inline-block;margin-top:20px;padding:12px 20px;border-radius:13px;background:oklch(0.585 0.214 299);color:#fff;font-weight:800;font-size:14px">Baixar na App Store</a>
        </div>
      </div>
      <p style="margin:30px auto 0;max-width:540px;font-size:15px;line-height:1.5;color:oklch(0.72 0.014 260)">
        Primeiro a banda, depois a rota. Um número alto de download não garante partida estável, e uma rota boa não resolve internet lenta.
      </p>
    </div>
  </section>

  <!-- ACESSO / DOWNLOAD APP STORE -->
  <section id="acesso" style="margin-top:100px;padding:110px 22px;text-align:center;background:radial-gradient(ellipse 70% 80% at 50% 100%,oklch(0.3 0.13 299 / 0.5),transparent 70%),oklch(0.15 0.012 260)">
    <div data-rv="1" style="max-width:640px;margin:auto">
      <img src="/assets/app-home.webp" alt="App Lagcheck" style="width:120px;border-radius:26px;margin-bottom:28px;animation:glow 2.4s infinite;border:1px solid oklch(0.4 0.012 260)">
      <h2 style="margin:0;font:900 clamp(38px,6vw,64px)/.95 ui-rounded,system-ui,sans-serif;letter-spacing:-.06em">Faça o check antes da próxima fila.</h2>
      <p style="margin:18px 0 32px;color:oklch(0.75 0.014 260);font-size:17px;line-height:1.45">
        Disponível agora na App Store para iPhone. Gratuito e sem anúncios.
      </p>
      
      <!-- BOTÃO APP STORE -->
      <div style="display:flex;justify-content:center">
        <a href="${APP_STORE_URL}" target="_blank" rel="noopener noreferrer" data-track-conversion="appstore" aria-label="Baixar na App Store" class="btn-appstore" style="display:inline-block">
          <img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/pt-br?size=250x83" alt="Baixar na App Store" style="height:56px;display:block">
        </a>
      </div>
    </div>
  </section>

  ${buildFooter()}
</div>
${TELEMETRY_AND_CONVERSION_SCRIPT}
</body>
</html>
`;
}

// 2. GERAR O HUB DE JOGOS (web/jogos/index.html)
function generateJogosHub() {
  const cardsHtml = GAMES.map(g => `
    <a href="/jogos/${g.slug}/" style="display:block;border-radius:26px;overflow:hidden;background:oklch(0.2 0.012 260);border:1px solid oklch(0.3 0.014 260);transition:transform .3s,border-color .3s">
      <div style="aspect-ratio:1;overflow:hidden">
        <img src="/assets/games/${g.file}.jpg" alt="${g.name}" style="width:100%;height:100%;object-fit:cover;display:block">
      </div>
      <div style="padding:20px 22px 24px">
        <h2 style="margin:0;font:850 24px ui-rounded,system-ui,sans-serif;letter-spacing:-.045em">Testar ping no ${g.name}</h2>
        <p style="margin:8px 0 0;font:11px ui-monospace,monospace;color:oklch(0.675 0.014 260)">${g.platforms}</p>
      </div>
    </a>
  `).join('');

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Testar ping e lag nos seus jogos | Lagcheck</title>
  <meta name="description" content="Escolha seu jogo e veja se sua conexão aguenta o ranked: Fortnite, Free Fire, COD Mobile, Valorant e mais. Latência, jitter e perda de pacotes no Lagcheck.">
  <meta name="robots" content="index,follow">
  <meta name="apple-itunes-app" content="app-id=6818706960">
  <link rel="canonical" href="https://lagcheck.signallq.com/jogos/">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
  <meta name="theme-color" content="#0B0D10">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="pt_BR">
  <meta property="og:site_name" content="Lagcheck">
  <meta property="og:title" content="Testar ping e lag nos seus jogos | Lagcheck">
  <meta property="og:description" content="Escolha seu jogo e veja se sua conexão aguenta o ranked: Fortnite, Free Fire, COD Mobile e mais. Disponível na App Store.">
  <meta property="og:url" content="https://lagcheck.signallq.com/jogos/">
  <meta property="og:image" content="https://lagcheck.signallq.com/og.png">
  <meta name="twitter:card" content="summary_large_image">
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    "itemListElement": [
      { "@type": "ListItem", "position": 1, "name": "Lagcheck", "item": "https://lagcheck.signallq.com/" },
      { "@type": "ListItem", "position": 2, "name": "Jogos", "item": "https://lagcheck.signallq.com/jogos/" }
    ]
  }
  </script>
  <style>${COMMON_CSS}</style>
</head>
<body>
<div>
  ${buildHeader('jogos')}
  <main style="max-width:1100px;margin:auto;padding:70px 22px 90px">
    <p style="margin:0 0 16px;font:11px ui-monospace,monospace;letter-spacing:.12em;text-transform:uppercase;color:oklch(0.78 0.12 299);animation:rise .8s both">Jogos</p>
    <h1 style="margin:0;max-width:780px;font:900 clamp(42px,6.5vw,84px)/.93 ui-rounded,system-ui,sans-serif;letter-spacing:-.06em;animation:rise .8s .1s both">
      Escolha o jogo. Veja se a conexão aguenta.
    </h1>
    <p style="margin:22px 0 0;max-width:560px;font-size:19px;line-height:1.45;color:oklch(0.75 0.014 260);animation:rise .8s .2s both">
      Guias para testar ping e entender o lag nos jogos mais jogados. Cada guia explica o que o check mede e por que a conexão pode falhar.
    </p>
    <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:18px;margin-top:56px">
      ${cardsHtml}
    </div>
  </main>
  ${buildFooter()}
</div>
${TELEMETRY_AND_CONVERSION_SCRIPT}
</body>
</html>
`;
}

// 3. GERAR PÁGINA INDIVIDUAL DE JOGO (web/jogos/<slug>/index.html)
function generateGamePage(game) {
  const others = GAMES.filter(g => g.slug !== game.slug).slice(0, 6);
  const othersHtml = others.map(o => `
    <a href="/jogos/${o.slug}/" style="padding:12px 18px;border-radius:999px;border:1px solid oklch(0.35 0.014 260);font-weight:700;font-size:14px">
      Testar ping no ${o.name}
    </a>
  `).join('');

  const routeText = getRouteText(game.infra);

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Testar ping no ${game.name} | Lagcheck</title>
  <meta name="description" content="Teste o ping e o lag no ${game.name}: latência, jitter e perda de pacotes antes de entrar na partida. Veredito em 25–35 segundos no Lagcheck para iPhone.">
  <meta name="robots" content="index,follow">
  <meta name="apple-itunes-app" content="app-id=6818706960">
  <link rel="canonical" href="https://lagcheck.signallq.com/jogos/${game.slug}/">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
  <meta name="theme-color" content="#0B0D10">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="pt_BR">
  <meta property="og:site_name" content="Lagcheck">
  <meta property="og:title" content="Testar ping no ${game.name} | Lagcheck">
  <meta property="og:description" content="Teste o ping e o lag no ${game.name}: latência, jitter e perda de pacotes antes de entrar na partida. Veredito em 25–35 segundos no Lagcheck para iPhone.">
  <meta property="og:url" content="https://lagcheck.signallq.com/jogos/${game.slug}/">
  <meta property="og:image" content="https://lagcheck.signallq.com/assets/games/${game.file}.jpg">
  <meta name="twitter:card" content="summary_large_image">
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "BreadcrumbList",
        "itemListElement": [
          { "@type": "ListItem", "position": 1, "name": "Lagcheck", "item": "https://lagcheck.signallq.com/" },
          { "@type": "ListItem", "position": 2, "name": "Jogos", "item": "https://lagcheck.signallq.com/jogos/" },
          { "@type": "ListItem", "position": 3, "name": "${game.name}", "item": "https://lagcheck.signallq.com/jogos/${game.slug}/" }
        ]
      },
      {
        "@type": "MobileApplication",
        "name": "Lagcheck: Teste de Ping Gamer",
        "operatingSystem": "iOS 17.0+",
        "applicationCategory": "UtilitiesApplication",
        "offers": { "@type": "Offer", "price": "0", "priceCurrency": "BRL" },
        "description": "App que diagnostica latência, jitter e perda de pacotes para ${game.name} antes do ranked.",
        "url": "${APP_STORE_URL}"
      },
      {
        "@type": "FAQPage",
        "mainEntity": [
          {
            "@type": "Question",
            "name": "Como testar o ping no ${game.name}?",
            "acceptedAnswer": { "@type": "Answer", "text": "Abra o Lagcheck no iPhone, escolha ${game.name} e faça o check. Em cerca de 25–35 segundos você recebe o veredito." }
          },
          {
            "@type": "Question",
            "name": "Por que o ${game.name} dá lag mesmo com internet rápida?",
            "acceptedAnswer": { "@type": "Answer", "text": "Velocidade não é estabilidade. Jitter, perda de pacotes e fila no roteador sob carga causam lag mesmo com banda alta." }
          },
          {
            "@type": "Question",
            "name": "O Lagcheck mostra o ping oficial do ${game.name}?",
            "acceptedAnswer": { "@type": "Answer", "text": "Não. Ele mede uma rota de referência regional e diz isso com clareza, sem prometer o ping da próxima partida." }
          }
        ]
      }
    ]
  }
  </script>
  <style>${COMMON_CSS}</style>
</head>
<body>
<div>
  ${buildHeader('jogos')}

  <!-- HERO DO JOGO -->
  <section style="position:relative;min-height:clamp(560px,88vh,820px);display:flex;align-items:flex-end;overflow:hidden;background:oklch(0.12 0.01 260)">
    <img src="/assets/games/${game.file}.jpg" alt="Capa de ${game.name}" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover;object-position:center 30%;transform:scale(1.04);animation:kb 18s ease-in-out infinite alternate">
    <div style="position:absolute;inset:0;background:linear-gradient(180deg,oklch(0.12 0.01 260 / 0.55) 0%,oklch(0.12 0.01 260 / 0.1) 30%,oklch(0.12 0.01 260 / 0.7) 70%,oklch(0.12 0.01 260) 100%)"></div>
    <div style="position:relative;width:100%;max-width:1100px;margin:auto;padding:0 22px 64px">
      <nav aria-label="Trilha" style="margin-bottom:26px;font:11px ui-monospace,monospace;color:oklch(0.85 0.01 260)">
        <a href="/">Lagcheck</a> / <a href="/jogos/">Jogos</a> / ${game.name}
      </nav>
      <p class="hi" style="margin:0 0 16px;font:11px ui-monospace,monospace;letter-spacing:.12em;text-transform:uppercase;color:oklch(0.85 0.1 299)">${game.platforms}</p>
      <h1 class="hi" style="animation-delay:.1s;margin:0;max-width:900px;font:900 clamp(46px,8vw,112px)/.9 ui-rounded,system-ui,sans-serif;letter-spacing:-.065em;text-wrap:balance;text-shadow:0 4px 40px #0008">
        Testar ping no ${game.name}
      </h1>
      <p class="hi" style="animation-delay:.2s;margin:24px 0 0;max-width:560px;font-size:20px;line-height:1.4;color:oklch(0.92 0.008 260)">
        Descubra se sua conexão está estável antes de entrar na fila de ${game.name}. O Lagcheck mede latência, jitter e perda de pacotes e entrega um veredito claro.
      </p>
      <div class="hi" style="animation-delay:.3s;margin-top:32px">
        <a href="${APP_STORE_URL}" target="_blank" rel="noopener noreferrer" data-track-conversion="appstore" aria-label="Baixar na App Store" class="btn-appstore">
          <img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/pt-br?size=250x83" alt="Baixar na App Store" style="height:56px;display:block">
        </a>
      </div>
    </div>
  </section>

  <main style="max-width:1100px;margin:auto;padding:70px 22px 0">
    <!-- MÉTRICAS -->
    <section style="padding:0 0 70px">
      <h2 style="margin:0 0 26px;font:850 clamp(28px,3.6vw,42px)/1 ui-rounded,system-ui,sans-serif;letter-spacing:-.05em">
        O que o check mede para ${game.name}
      </h2>
      <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:14px">
        <article style="padding:24px;border-radius:22px;background:oklch(0.2 0.012 260);border:1px solid oklch(0.3 0.014 260)">
          <h3 style="margin:0;font:850 20px ui-rounded,system-ui,sans-serif;letter-spacing:-.04em">Latência</h3>
          <p style="margin:10px 0 0;font-size:14px;line-height:1.5;color:oklch(0.72 0.014 260)">Tempo de ida e volta dos pacotes UDP até o destino regional.</p>
        </article>
        <article style="padding:24px;border-radius:22px;background:oklch(0.2 0.012 260);border:1px solid oklch(0.3 0.014 260)">
          <h3 style="margin:0;font:850 20px ui-rounded,system-ui,sans-serif;letter-spacing:-.04em">Jitter</h3>
          <p style="margin:10px 0 0;font-size:14px;line-height:1.5;color:oklch(0.72 0.014 260)">A oscilação da latência, responsável por micro-travamentos e tiros que não conectam.</p>
        </article>
        <article style="padding:24px;border-radius:22px;background:oklch(0.2 0.012 260);border:1px solid oklch(0.3 0.014 260)">
          <h3 style="margin:0;font:850 20px ui-rounded,system-ui,sans-serif;letter-spacing:-.04em">Perda de pacotes</h3>
          <p style="margin:10px 0 0;font-size:14px;line-height:1.5;color:oklch(0.72 0.014 260)">Pacotes perdidos no percurso, que viram teleportes, rubber-banding e ações atrasadas.</p>
        </article>
        <article style="padding:24px;border-radius:22px;background:oklch(0.2 0.012 260);border:1px solid oklch(0.3 0.014 260)">
          <h3 style="margin:0;font:850 20px ui-rounded,system-ui,sans-serif;letter-spacing:-.04em">Sob carga</h3>
          <p style="margin:10px 0 0;font-size:14px;line-height:1.5;color:oklch(0.72 0.014 260)">Como a rota reage se alguém estiver assistindo streaming ou baixando algo na mesma rede.</p>
        </article>
      </div>
    </section>

    <!-- ROTA & CAUSAS -->
    <section style="padding:0 0 70px;display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:16px">
      <article style="padding:34px;border-radius:28px;background:linear-gradient(135deg,oklch(0.22 0.06 299),oklch(0.16 0.02 260))">
        <p style="margin:0 0 10px;font:11px ui-monospace,monospace;letter-spacing:.1em;text-transform:uppercase;color:oklch(0.78 0.12 299)">Rota medida</p>
        <h2 style="margin:0;font:850 28px/1.05 ui-rounded,system-ui,sans-serif;letter-spacing:-.045em">Referência AWS · São Paulo</h2>
        <p style="margin:14px 0 0;font-size:15px;line-height:1.5;color:oklch(0.8 0.014 260)">${routeText}</p>
        <p style="margin:12px 0 0;font-size:13px;line-height:1.5;color:oklch(0.65 0.014 260)">É uma rota de referência regional, não o servidor da sua próxima partida.</p>
      </article>
      <article style="padding:34px;border-radius:28px;background:oklch(0.2 0.012 260);border:1px solid oklch(0.3 0.014 260)">
        <p style="margin:0 0 10px;font:11px ui-monospace,monospace;letter-spacing:.1em;text-transform:uppercase;color:oklch(0.675 0.014 260)">Causas comuns de lag</p>
        <ul style="margin:0;padding:0;list-style:none;font-size:15px;line-height:1.5;color:oklch(0.8 0.012 260)">
          <li style="padding:11px 0;border-top:1px solid oklch(0.3 0.014 260)">Wi-Fi congestionado, canal saturado ou sinal fraco</li>
          <li style="padding:11px 0;border-top:1px solid oklch(0.3 0.014 260)">Bufferbloat: ping que explode quando a rede entra sob carga</li>
          <li style="padding:11px 0;border-top:1px solid oklch(0.3 0.014 260)">Rota instável ou degradação na operadora (ISP)</li>
          <li style="padding:11px 0;border-top:1px solid oklch(0.3 0.014 260)">Dados móveis com cobertura instável ou troca de torre</li>
        </ul>
      </article>
    </section>

    <!-- FAQ DO JOGO -->
    <section style="padding:0 0 70px">
      <h2 style="margin:0 0 24px;font:850 clamp(28px,3.6vw,42px)/1 ui-rounded,system-ui,sans-serif;letter-spacing:-.05em">
        Dúvidas sobre lag no ${game.name}
      </h2>
      <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:14px">
        <article style="padding:26px;border-radius:22px;background:oklch(0.2 0.012 260)">
          <h3 style="margin:0;font:800 19px/1.1 ui-rounded,system-ui,sans-serif;letter-spacing:-.04em">Como testar o ping no ${game.name}?</h3>
          <p style="margin:12px 0 0;font-size:14px;line-height:1.5;color:oklch(0.72 0.014 260)">Abra o Lagcheck no iPhone, escolha ${game.name} e faça o check. Em cerca de 25–35 segundos você recebe o veredito.</p>
        </article>
        <article style="padding:26px;border-radius:22px;background:oklch(0.2 0.012 260)">
          <h3 style="margin:0;font:800 19px/1.1 ui-rounded,system-ui,sans-serif;letter-spacing:-.04em">Por que o ${game.name} dá lag mesmo com internet rápida?</h3>
          <p style="margin:12px 0 0;font-size:14px;line-height:1.5;color:oklch(0.72 0.014 260)">Velocidade não é estabilidade. Jitter, perda de pacotes e fila no roteador sob carga causam lag mesmo com banda alta.</p>
        </article>
        <article style="padding:26px;border-radius:22px;background:oklch(0.2 0.012 260)">
          <h3 style="margin:0;font:800 19px/1.1 ui-rounded,system-ui,sans-serif;letter-spacing:-.04em">O Lagcheck mostra o ping oficial do ${game.name}?</h3>
          <p style="margin:12px 0 0;font-size:14px;line-height:1.5;color:oklch(0.72 0.014 260)">Não. Ele mede uma rota de referência regional e diz isso com clareza, sem prometer o ping da próxima partida.</p>
        </article>
      </div>
    </section>

    <!-- OUTROS JOGOS -->
    <section style="padding:0 0 90px">
      <h2 style="margin:0 0 20px;font:850 24px ui-rounded,system-ui,sans-serif;letter-spacing:-.04em">Outros jogos</h2>
      <div style="display:flex;gap:10px;flex-wrap:wrap">
        ${othersHtml}
        <a href="/jogos/" style="padding:12px 18px;border-radius:999px;background:oklch(0.585 0.214 299);color:#fff;font-weight:700;font-size:14px">Ver todos →</a>
      </div>
    </section>
  </main>

  ${buildFooter()}
</div>
${TELEMETRY_AND_CONVERSION_SCRIPT}
</body>
</html>
`;
}

// 4. GERAR SUPORTE (web/support/index.html e web/support.html)
function generateSupport() {
  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Suporte Oficial | Lagcheck</title>
  <meta name="description" content="Central de suporte e ajuda do Lagcheck para iPhone. Tire dúvidas sobre a medição de rota UDP, diagnósticos e vereditos.">
  <meta name="robots" content="index,follow">
  <meta name="apple-itunes-app" content="app-id=6818706960">
  <link rel="canonical" href="https://lagcheck.signallq.com/support/">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
  <meta name="theme-color" content="#0B0D10">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="pt_BR">
  <meta property="og:site_name" content="Lagcheck">
  <meta property="og:title" content="Suporte Oficial | Lagcheck">
  <meta property="og:description" content="Central de ajuda e suporte técnico do Lagcheck para iPhone.">
  <meta property="og:url" content="https://lagcheck.signallq.com/support/">
  <meta property="og:image" content="https://lagcheck.signallq.com/og.png">
  <meta name="twitter:card" content="summary_large_image">
  <style>${COMMON_CSS}</style>
</head>
<body>
<div>
  ${buildHeader('support')}
  <main style="max-width:900px;margin:auto;padding:70px 22px 100px">
    <p style="margin:0 0 16px;font:11px ui-monospace,monospace;letter-spacing:.12em;text-transform:uppercase;color:oklch(0.78 0.12 299);animation:rise .8s both">Suporte Oficial</p>
    <h1 style="margin:0;font:900 clamp(40px,6vw,72px)/.95 ui-rounded,system-ui,sans-serif;letter-spacing:-.06em;animation:rise .8s .1s both">
      Como podemos ajudar?
    </h1>
    <p style="margin:22px 0 0;max-width:640px;font-size:19px;line-height:1.45;color:oklch(0.75 0.014 260);animation:rise .8s .2s both">
      O Lagcheck está disponível na App Store para iPhone (iOS 17+). Se você tiver alguma dúvida técnica sobre sua medição, rotas ou feedback do app, fale com nosso time.
    </p>

    <div style="display:grid;gap:18px;margin-top:52px">
      <article style="padding:32px;border-radius:26px;background:oklch(0.2 0.012 260);border:1px solid oklch(0.3 0.014 260)">
        <h2 style="margin:0;font:850 24px ui-rounded,system-ui,sans-serif;letter-spacing:-.045em">O que o Lagcheck mede exatamente?</h2>
        <p style="margin:12px 0 0;font-size:16px;line-height:1.5;color:oklch(0.75 0.014 260)">
          Latência real (ping UDP), jitter (oscilação), descarte de pacotes (packet loss) e comportamento da rota sob carga concorrente (bufferbloat), entregando um veredito honesto antes da sua partida.
        </p>
      </article>

      <article style="padding:32px;border-radius:26px;background:oklch(0.2 0.012 260);border:1px solid oklch(0.3 0.014 260)">
        <h2 style="margin:0;font:850 24px ui-rounded,system-ui,sans-serif;letter-spacing:-.045em">O app mede o servidor do meu jogo ou uma rota de referência?</h2>
        <p style="margin:12px 0 0;font-size:16px;line-height:1.5;color:oklch(0.75 0.014 260)">
          O Lagcheck envia pacotes UDP para beacons regionais de referência (como AWS GameLift em São Paulo). Ele avalia a qualidade da rota e da sua rede local de forma determinística, sem inventar números.
        </p>
      </article>

      <article style="padding:32px;border-radius:26px;background:oklch(0.2 0.012 260);border:1px solid oklch(0.3 0.014 260)">
        <h2 style="margin:0;font:850 24px ui-rounded,system-ui,sans-serif;letter-spacing:-.045em">O que fazer quando o resultado der "Condições instáveis"?</h2>
        <p style="margin:12px 0 0;font-size:16px;line-height:1.5;color:oklch(0.75 0.014 260)">
          Recomendamos evitar filas ranqueadas no momento. Verifique se há downloads ativos na rede, aproxime-se do roteador Wi-Fi (ou prefira a banda 5 GHz) ou reinicie o modem caso a oscilação persista.
        </p>
      </article>

      <article style="padding:32px;border-radius:26px;background:linear-gradient(135deg,oklch(0.22 0.06 299),oklch(0.16 0.02 260));border:1px solid oklch(0.35 0.02 299);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:20px">
        <div>
          <h2 style="margin:0;font:850 24px ui-rounded,system-ui,sans-serif;letter-spacing:-.045em">Precisa falar com a gente?</h2>
          <p style="margin:8px 0 0;font-size:15px;color:oklch(0.85 0.01 260)">Nosso canal oficial de atendimento por e-mail.</p>
        </div>
        <a href="mailto:suporte@signallq.com" style="padding:14px 22px;border-radius:14px;background:oklch(0.585 0.214 299);color:#fff;font-weight:700;font-size:15px;text-decoration:none">
          suporte@signallq.com →
        </a>
      </article>
    </div>
  </main>
  ${buildFooter()}
</div>
${TELEMETRY_AND_CONVERSION_SCRIPT}
</body>
</html>
`;
}

// 5. GERAR PRIVACIDADE (web/privacy/index.html e web/privacy.html)
function generatePrivacy() {
  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Privacidade Oficial | Lagcheck</title>
  <meta name="description" content="Política de privacidade oficial do app Lagcheck na App Store. Sem contas, sem anúncios e com dados locais no iPhone.">
  <meta name="robots" content="index,follow">
  <meta name="apple-itunes-app" content="app-id=6818706960">
  <link rel="canonical" href="https://lagcheck.signallq.com/privacy/">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
  <meta name="theme-color" content="#0B0D10">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="pt_BR">
  <meta property="og:site_name" content="Lagcheck">
  <meta property="og:title" content="Privacidade Oficial | Lagcheck">
  <meta property="og:description" content="Política de privacidade oficial do app Lagcheck para iPhone.">
  <meta property="og:url" content="https://lagcheck.signallq.com/privacy/">
  <meta property="og:image" content="https://lagcheck.signallq.com/og.png">
  <meta name="twitter:card" content="summary_large_image">
  <style>${COMMON_CSS}</style>
</head>
<body>
<div>
  ${buildHeader('privacy')}
  <main style="max-width:900px;margin:auto;padding:70px 22px 100px">
    <p style="margin:0 0 16px;font:11px ui-monospace,monospace;letter-spacing:.12em;text-transform:uppercase;color:oklch(0.78 0.12 299);animation:rise .8s both">Privacidade Oficial</p>
    <h1 style="margin:0;font:900 clamp(40px,6vw,72px)/.95 ui-rounded,system-ui,sans-serif;letter-spacing:-.06em;animation:rise .8s .1s both">
      Privacidade em primeiro lugar.
    </h1>
    <p style="margin:22px 0 0;max-width:640px;font-size:19px;line-height:1.45;color:oklch(0.75 0.014 260);animation:rise .8s .2s both">
      O Lagcheck foi projetado com respeito absoluto aos seus dados. Sem contas, sem anúncios e sem rastreamento de navegação.
    </p>

    <div style="display:grid;gap:18px;margin-top:52px">
      <article style="padding:32px;border-radius:26px;background:oklch(0.2 0.012 260);border:1px solid oklch(0.3 0.014 260)">
        <h2 style="margin:0;font:850 24px ui-rounded,system-ui,sans-serif;letter-spacing:-.045em">Zero Coleta de Dados Pessoais</h2>
        <p style="margin:12px 0 0;font-size:16px;line-height:1.5;color:oklch(0.75 0.014 260)">
          O app não exige cadastro, e-mail, login ou número de telefone. Você baixa e mede imediatamente, sem qualquer identificação de usuário.
        </p>
      </article>

      <article style="padding:32px;border-radius:26px;background:oklch(0.2 0.012 260);border:1px solid oklch(0.3 0.014 260)">
        <h2 style="margin:0;font:850 24px ui-rounded,system-ui,sans-serif;letter-spacing:-.045em">Armazenamento Local no iPhone (SwiftData)</h2>
        <p style="margin:12px 0 0;font-size:16px;line-height:1.5;color:oklch(0.75 0.014 260)">
          O histórico das suas medições de rede fica armazenado exclusivamente no armazenamento local seguro do seu próprio iPhone. Seus dados nunca são vendidos ou compartilhados.
        </p>
      </article>

      <article style="padding:32px;border-radius:26px;background:oklch(0.2 0.012 260);border:1px solid oklch(0.3 0.014 260)">
        <h2 style="margin:0;font:850 24px ui-rounded,system-ui,sans-serif;letter-spacing:-.045em">Diagnóstico Técnico Anônimo</h2>
        <p style="margin:12px 0 0;font-size:16px;line-height:1.5;color:oklch(0.75 0.014 260)">
          Para manter a estabilidade do serviço e aprimorar as rotas, enviamos telemetria técnica agregada estritamente anônima (como versão do iOS e tempos de resposta agregados), sem registrar endereços de IP ou informações de identificação pessoal.
        </p>
      </article>

      <article style="padding:32px;border-radius:26px;background:linear-gradient(135deg,oklch(0.22 0.06 299),oklch(0.16 0.02 260));border:1px solid oklch(0.35 0.02 299);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:20px">
        <div>
          <h2 style="margin:0;font:850 24px ui-rounded,system-ui,sans-serif;letter-spacing:-.045em">Dúvidas sobre seus dados?</h2>
          <p style="margin:8px 0 0;font-size:15px;color:oklch(0.85 0.01 260)">Fale com nosso encarregado de privacidade.</p>
        </div>
        <a href="mailto:suporte@signallq.com" style="padding:14px 22px;border-radius:14px;background:oklch(0.585 0.214 299);color:#fff;font-weight:700;font-size:15px;text-decoration:none">
          suporte@signallq.com →
        </a>
      </article>
    </div>
  </main>
  ${buildFooter()}
</div>
${TELEMETRY_AND_CONVERSION_SCRIPT}
</body>
</html>
`;
}

// 6. GERAR SITEMAP & ROBOTS
function generateSitemap() {
  const today = '2026-10-11';
  const urls = [
    { loc: 'https://lagcheck.signallq.com/', priority: '1.0' },
    { loc: 'https://lagcheck.signallq.com/jogos/', priority: '0.9' },
    ...GAMES.map(g => ({ loc: `https://lagcheck.signallq.com/jogos/${g.slug}/`, priority: '0.8' })),
    { loc: 'https://lagcheck.signallq.com/support/', priority: '0.3' },
    { loc: 'https://lagcheck.signallq.com/privacy/', priority: '0.3' }
  ];

  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.map(u => `  <url><loc>${u.loc}</loc><lastmod>${today}</lastmod><priority>${u.priority}</priority></url>`).join('\n')}
</urlset>
`;
}

function generateRobots() {
  return `User-agent: *
Allow: /

Sitemap: https://lagcheck.signallq.com/sitemap.xml
`;
}

// EXECUÇÃO DO BUILD
console.log('🚀 Iniciando geração da webpage do Lagcheck (App Store Live)...');

// Escreve index.html
fs.writeFileSync(path.join(WEB_DIR, 'index.html'), generateHome(), 'utf8');
console.log('✅ Home gerada: web/index.html');

// Escreve web/jogos/index.html
const jogosDir = path.join(WEB_DIR, 'jogos');
fs.mkdirSync(jogosDir, { recursive: true });
fs.writeFileSync(path.join(jogosDir, 'index.html'), generateJogosHub(), 'utf8');
console.log('✅ Hub de jogos gerado: web/jogos/index.html');

// Escreve páginas individuais dos 20 jogos
for (const game of GAMES) {
  const gameDir = path.join(jogosDir, game.slug);
  fs.mkdirSync(gameDir, { recursive: true });
  fs.writeFileSync(path.join(gameDir, 'index.html'), generateGamePage(game), 'utf8');
}
console.log(`✅ 20 páginas de jogos geradas em web/jogos/<slug>/index.html`);

// Escreve Suporte (index.html e fallback raiz)
const supportDir = path.join(WEB_DIR, 'support');
fs.mkdirSync(supportDir, { recursive: true });
const supportHtml = generateSupport();
fs.writeFileSync(path.join(supportDir, 'index.html'), supportHtml, 'utf8');
fs.writeFileSync(path.join(WEB_DIR, 'support.html'), supportHtml, 'utf8');
console.log('✅ Suporte gerado em web/support/index.html e web/support.html');

// Escreve Privacidade (index.html e fallback raiz)
const privacyDir = path.join(WEB_DIR, 'privacy');
fs.mkdirSync(privacyDir, { recursive: true });
const privacyHtml = generatePrivacy();
fs.writeFileSync(path.join(privacyDir, 'index.html'), privacyHtml, 'utf8');
fs.writeFileSync(path.join(WEB_DIR, 'privacy.html'), privacyHtml, 'utf8');
console.log('✅ Privacidade gerada em web/privacy/index.html e web/privacy.html');

// Escreve sitemap.xml e robots.txt
fs.writeFileSync(path.join(WEB_DIR, 'sitemap.xml'), generateSitemap(), 'utf8');
fs.writeFileSync(path.join(WEB_DIR, 'robots.txt'), generateRobots(), 'utf8');
console.log('✅ sitemap.xml e robots.txt atualizados');

console.log('🏁 Build concluído com sucesso!');

