/**
 * Lagcheck — Automated Validation Suite para a nova Webpage
 * Valida a integridade dos 20 jogos, rotas, SEO, ASO, schemas JSON-LD e HTTP 200.
 */

const fs = require('fs');
const path = require('path');
const http = require('http');

const WEB_DIR = path.resolve(__dirname);

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

function assert(condition, message) {
  totalTests++;
  if (condition) {
    passedTests++;
    console.log(`  ✓ ${message}`);
  } else {
    failedTests++;
    console.error(`  ✗ FAIL: ${message}`);
  }
}

const GAMES = [
  'fortnite', 'free-fire', 'cod-mobile', 'valorant', 'counter-strike-2',
  'apex-legends', 'league-of-legends', 'wild-rift', 'rocket-league', 'roblox',
  'minecraft', 'brawl-stars', 'warzone', 'pubg-mobile', 'blood-strike',
  'dota-2', 'ea-sports-fc', 'palworld', 'rainbow-six-siege', 'rust'
];

console.log('\n--- 1. Verificação de Estrutura de Arquivos Obrigatórios ---');
const baseFiles = [
  'index.html',
  'jogos/index.html',
  'support.html',
  'support/index.html',
  'privacy.html',
  'privacy/index.html',
  'robots.txt',
  'sitemap.xml',
  'og.png',
  'favicon.ico',
  'favicon.svg',
  'apple-touch-icon.png',
  'assets/app-home.webp',
  'assets/app-games.webp',
  'assets/app-result.webp',
  'assets/lagcheck-wordmark-light.svg'
];

baseFiles.forEach(f => {
  assert(fs.existsSync(path.join(WEB_DIR, f)), `Arquivo base existe: ${f}`);
});

console.log('\n--- 2. Verificação dos 20 Jogos e Imagens de Alta Resolução ---');
GAMES.forEach(slug => {
  const gameHtml = path.join(WEB_DIR, 'jogos', slug, 'index.html');
  assert(fs.existsSync(gameHtml), `Página do jogo existe: jogos/${slug}/index.html`);
});

const gameImages = fs.readdirSync(path.join(WEB_DIR, 'assets', 'games'));
assert(gameImages.length >= 20, `Mínimo de 20 artes de jogos presentes em assets/games (encontrados: ${gameImages.length})`);

console.log('\n--- 3. Verificação de SEO e Schemas JSON-LD na Home ---');
const indexHtml = fs.readFileSync(path.join(WEB_DIR, 'index.html'), 'utf-8');

assert(indexHtml.includes('<title>Lagcheck — Teste de lag: sua conexão aguenta o ranked?</title>'), 'SEO Home: Title exato');
assert(indexHtml.includes('name="description"'), 'SEO Home: Meta description configurada');
assert(indexHtml.includes('property="og:image" content="https://lagcheck.signallq.com/og.png"'), 'SEO Home: OG Image configurada');
assert(indexHtml.includes('"@type": "MobileApplication"'), 'Schema Home: MobileApplication presente');
assert(indexHtml.includes('"@type": "FAQPage"'), 'Schema Home: FAQPage presente');
assert(indexHtml.includes('name="apple-itunes-app"'), 'ASO Home: Smart App Banner configurado');
assert(indexHtml.includes('/v1/visit'), 'Telemetria Home: Endpoint /v1/visit presente');
assert(indexHtml.includes('https://apps.apple.com/br/app/lagcheck-teste-de-ping-gamer/id6818706960'), 'ASO Home: Link oficial do Lagcheck id6818706960 presente');
assert(indexHtml.includes('https://apps.apple.com/app/id6808479321'), 'Linka: Link de download na App Store presente');
assert(fs.existsSync(path.join(WEB_DIR, 'assets', 'linka-icon.png')), 'Linka: Ícone presente em assets/linka-icon.png');
assert(indexHtml.includes('https://signallq.com'), 'SignallQ: Link oficial presente no ecossistema/rodapé');

console.log('\n--- 4. Verificação de Navegação Mobile e Conversão Limpa ---');
assert(indexHtml.includes('id="mobile-menu-btn"'), 'Navegação Mobile: Botão de menu hambúrguer presente');
assert(indexHtml.includes('id="mobile-nav"'), 'Navegação Mobile: Drawer/menu móvel presente');
assert(indexHtml.includes('aria-expanded="false"'), 'Navegação Mobile: Controle acessível aria-expanded');
assert(indexHtml.includes('aria-controls="mobile-nav"'), 'Navegação Mobile: Controle acessível aria-controls');
assert(!indexHtml.includes('appstore_download@click.local'), 'Conversão: Sem e-mail fictício no tracking da App Store');
assert(!indexHtml.includes('/v1/waitlist'), 'Conversão: Cliques da App Store não corrompem a rota de waitlist');
assert(indexHtml.includes('/v1/click'), 'Conversão: Endpoint dedicado /v1/click configurado para intenção de instalação');

console.log('\n--- 5. Verificação de Suporte e Privacidade (Dark UI Padrão 1:1) ---');
const supportHtml = fs.readFileSync(path.join(WEB_DIR, 'support', 'index.html'), 'utf-8');
assert(supportHtml.includes('https://apps.apple.com/br/app/lagcheck-teste-de-ping-gamer/id6818706960'), 'Suporte: Link oficial do Lagcheck id6818706960 presente');
assert(supportHtml.includes('suporte@signallq.com'), 'Suporte: E-mail de atendimento presente');
assert(supportHtml.includes('/assets/lagcheck-wordmark-light.svg'), 'Suporte: Header oficial com wordmark presente');

const privacyHtml = fs.readFileSync(path.join(WEB_DIR, 'privacy', 'index.html'), 'utf-8');
assert(privacyHtml.includes('https://apps.apple.com/br/app/lagcheck-teste-de-ping-gamer/id6818706960'), 'Privacidade: Link oficial do Lagcheck id6818706960 presente');
assert(privacyHtml.includes('Zero Coleta de Dados Pessoais'), 'Privacidade: Conformidade oficial App Store');
assert(privacyHtml.includes('/assets/lagcheck-wordmark-light.svg'), 'Privacidade: Header oficial com wordmark presente');

console.log('\n--- 6. Verificação de SEO, Conteúdo Específico e Schemas nos Jogos ---');
const valorantHtml = fs.readFileSync(path.join(WEB_DIR, 'jogos', 'valorant', 'index.html'), 'utf-8');
assert(valorantHtml.includes('Testar ping no Valorant | Lagcheck'), 'SEO Jogo: Title personalizado de Valorant');
assert(valorantHtml.includes('"@type": "BreadcrumbList"'), 'Schema Jogo: BreadcrumbList presente');
assert(valorantHtml.includes('"@type": "FAQPage"'), 'Schema Jogo: FAQPage presente');
assert(valorantHtml.includes('/v1/visit'), 'Telemetria Jogo: Endpoint /v1/visit presente');
assert(valorantHtml.includes('/v1/click'), 'Conversão Jogo: Endpoint /v1/click presente');
assert(valorantHtml.includes('https://lagcheck.signallq.com/jogos/valorant/'), 'SEO Jogo: Canonical URL exata');

const cs2Html = fs.readFileSync(path.join(WEB_DIR, 'jogos', 'counter-strike-2', 'index.html'), 'utf-8');
assert(!cs2Html.includes('escolhido pelo operador de cada mundo'), 'CS2: Sem descrição incorreta de servidor comunitário genérico');
assert(cs2Html.includes('Steam Datagram Relay') || cs2Html.includes('Valve'), 'CS2: Descrição precisa da infraestrutura Valve');

const mcHtml = fs.readFileSync(path.join(WEB_DIR, 'jogos', 'minecraft', 'index.html'), 'utf-8');
assert(!mcHtml.includes('tiros que não conectam'), 'Minecraft: Sem descrição incorreta de tiros FPS em Minecraft');

assert(fs.existsSync(path.join(WEB_DIR, 'assets', 'games', 'valorant-thumb.webp')), 'Performance: Thumbnail WebP gerado para Valorant');
assert(fs.existsSync(path.join(WEB_DIR, 'assets', 'games', 'valorant.webp')), 'Performance: Hero WebP gerado para Valorant');

console.log('\n--- 7. Verificação do Sitemap e Robots ---');
const sitemapXml = fs.readFileSync(path.join(WEB_DIR, 'sitemap.xml'), 'utf-8');
assert(sitemapXml.includes('https://lagcheck.signallq.com/'), 'Sitemap: Contém URL da Home');
assert(sitemapXml.includes('https://lagcheck.signallq.com/jogos/'), 'Sitemap: Contém URL do Hub');
GAMES.forEach(slug => {
  assert(sitemapXml.includes(`https://lagcheck.signallq.com/jogos/${slug}/`), `Sitemap: Contém jogo ${slug}`);
});

const robotsTxt = fs.readFileSync(path.join(WEB_DIR, 'robots.txt'), 'utf-8');
assert(robotsTxt.includes('Sitemap: https://lagcheck.signallq.com/sitemap.xml'), 'Robots: Aponta para o sitemap correto');

console.log('\n--- 6. Teste de Servidor HTTP Local (Status 200 OK) ---');
const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.txt': 'text/plain; charset=utf-8',
  '.xml': 'application/xml; charset=utf-8'
};

const server = http.createServer((req, res) => {
  let reqPath = req.url.split('?')[0];
  if (reqPath.endsWith('/')) {
    reqPath += 'index.html';
  }

  const filePath = path.join(WEB_DIR, reqPath);
  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    const ext = path.extname(filePath);
    res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'application/octet-stream' });
    fs.createReadStream(filePath).pipe(res);
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});

const PORT = 8192;
server.listen(PORT, async () => {
  const routesToTest = [
    '/',
    '/index.html',
    '/jogos/',
    '/jogos/index.html',
    '/jogos/fortnite/',
    '/jogos/valorant/',
    '/jogos/counter-strike-2/',
    '/jogos/free-fire/',
    '/jogos/cod-mobile/',
    '/support/',
    '/privacy/',
    '/robots.txt',
    '/sitemap.xml',
    '/assets/lagcheck-wordmark-light.svg',
    '/assets/app-home.webp',
    '/assets/app-games.webp',
    '/assets/app-result.webp',
    '/assets/games/valorant.jpg',
    '/assets/games/valorant-thumb.webp',
    '/assets/games/valorant.webp',
    '/assets/games/fortnite.jpg',
    '/assets/linka-icon.png'
  ];

  for (const route of routesToTest) {
    await new Promise((resolve) => {
      http.get({
        hostname: '127.0.0.1',
        port: PORT,
        path: route,
        agent: false
      }, (res) => {
        assert(res.statusCode === 200, `Rota HTTP ${route} responde com status 200`);
        res.resume();
        resolve();
      }).on('error', (err) => {
        assert(false, `Falha ao acessar ${route}: ${err.message}`);
        resolve();
      });
    });
  }

  server.close(() => {
    console.log('\n========================================');
    console.log(`Resumo dos Testes: ${passedTests}/${totalTests} passaram`);
    if (failedTests === 0) {
      console.log('Status: Todos os testes passaram com sucesso! ✓\n');
      process.exit(0);
    } else {
      console.error(`Status: ${failedTests} testes falharam! ✗\n`);
      process.exit(1);
    }
  });
});
