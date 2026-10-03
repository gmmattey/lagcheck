/**
 * Lagcheck — Pre-Launch Website Automated Validation Suite
 * Valida a reconstrução da landing page e páginas auxiliares conforme a fonte de verdade do protótipo.
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

console.log('\n--- 1. Verificação de Estrutura de Arquivos Obrigatórios ---');
const requiredFiles = [
  'index.html',
  'support.html',
  'support/index.html',
  'privacy.html',
  'privacy/index.html',
  'css/style.css',
  'assets/lagcheck-wordmark-light.svg',
  'Screenshot-iPhone-17-Pro-27-09-2026-at-19.05.37.png',
  'Screenshot-iPhone-17-Pro-27-09-2026-at-19.05.13.png',
  'robots.txt',
  'sitemap.xml',
  'og.png',
  'favicon.ico',
  'favicon.svg',
  'apple-touch-icon.png',
  'assets/app-home.webp',
  'assets/app-games.webp'
];

requiredFiles.forEach((relPath) => {
  const fullPath = path.join(WEB_DIR, relPath);
  assert(fs.existsSync(fullPath), `Arquivo existe: ${relPath}`);
});

console.log('\n--- 2. Verificação de Grafia Estrita e Wordmark Oficial ---');
const textFilesToCheck = [
  'index.html',
  'support.html',
  'support/index.html',
  'privacy.html',
  'privacy/index.html',
  'assets/lagcheck-wordmark-light.svg'
];

textFilesToCheck.forEach((relPath) => {
  const content = fs.readFileSync(path.join(WEB_DIR, relPath), 'utf-8');
  assert(!content.includes('LagCheck'), `${relPath}: Grafia 'Lagcheck' respeitada (nunca 'LagCheck')`);
  assert(content.includes('Lagcheck'), `${relPath}: Contém 'Lagcheck' corretamente grafado`);
});

const indexHtml = fs.readFileSync(path.join(WEB_DIR, 'index.html'), 'utf-8');
assert(indexHtml.includes('src="assets/lagcheck-wordmark-light.svg"'), 'index.html usa wordmark SVG oficial');

console.log('\n--- 3. Verificação de Tokens Visuais e Dark Competitive UI ---');
const cssContent = fs.readFileSync(path.join(WEB_DIR, 'css', 'style.css'), 'utf-8');
const expectedTokens = [
  '--bg: oklch(.158 .011 260)',
  '--surface: oklch(.205 .012 260)',
  '--fg: oklch(.955 .006 260)',
  '--muted: oklch(.675 .014 260)',
  '--border: oklch(.302 .014 260)',
  '--accent: oklch(.585 .214 299)',
  '--good: oklch(.76 .15 150)',
  '--attention: oklch(.684 .196 35)',
  '--font-display: ui-rounded',
  '--font-body: -apple-system',
  '--font-mono: ui-monospace'
];

expectedTokens.forEach((token) => {
  assert(cssContent.includes(token), `Token presente em style.css: ${token}`);
  assert(indexHtml.includes(token), `Token presente no style inline de index.html: ${token}`);
});

console.log('\n--- 4. Verificação de Estrutura Obrigatória da Landing Page ---');
assert(indexHtml.includes('<title>Lagcheck — Teste de lag: sua conexão aguenta o ranked?</title>'), 'SEO: Title exato');
assert(indexHtml.includes('name="description" content="Meça latência, jitter e perda de pacotes antes do ranked e saiba se sua conexão aguenta. Em breve no iPhone e Android: entre na lista."'), 'SEO: Meta description exata');
assert(indexHtml.includes('property="og:image" content="https://lagcheck.signallq.com/og.png"'), 'SEO: Open Graph image 1200x630 configurado');
assert(indexHtml.includes('property="og:image:width" content="1200"') && indexHtml.includes('property="og:image:height" content="630"'), 'SEO: og:image com dimensões 1200x630');
const sitemapXml = fs.readFileSync(path.join(WEB_DIR, 'sitemap.xml'), 'utf-8');
assert(!sitemapXml.includes('/support/') && !sitemapXml.includes('/privacy/'), 'SEO: sitemap lista só URLs indexáveis (suporte e privacidade são noindex)');
assert(indexHtml.includes('"@type": "MobileApplication"') && !indexHtml.includes('GameApplication'), 'SEO: JSON-LD MobileApplication com categoria única');
assert(indexHtml.includes('name="twitter:card" content="summary_large_image"'), 'SEO: Twitter Card configurado');

// Hero
assert(indexHtml.includes('Sua conexão está pronta para ranked?'), 'Hero: Headline principal');
assert(indexHtml.includes('O Lagcheck mede a qualidade real da sua rota'), 'Hero: Explicação objetiva');
assert(indexHtml.includes('Entrar no TestFlight'), 'Hero CTA: TestFlight');
assert(indexHtml.includes('Entrar no Play Beta'), 'Hero CTA: Play Beta');
assert(indexHtml.includes('Screenshot-iPhone-17-Pro-27-09-2026-at-19.05.37.png'), 'Hero: Captura Fortnite Home em primeiro plano');
assert(indexHtml.includes('Screenshot-iPhone-17-Pro-27-09-2026-at-19.05.13.png'), 'Hero: Captura Jogos em apoio');

// 3 Passos
assert(indexHtml.includes('Escolhe o jogo'), 'Passo 1: Escolhe o jogo');
assert(indexHtml.includes('Faz o Check'), 'Passo 2: Faz o Check');
assert(indexHtml.includes('Recebe o veredito'), 'Passo 3: Recebe o veredito');

// Casos de Uso
assert(indexHtml.includes('Ranked'), 'Caso de uso: Ranked');
assert(indexHtml.includes('Casual'), 'Caso de uso: Casual');
assert(indexHtml.includes('Party / Discord'), 'Caso de uso: Party / Discord');
assert(indexHtml.includes('Streaming + jogo'), 'Caso de uso: Streaming + jogo');

// Jogos Previstos
assert(indexHtml.includes('Fortnite'), 'Jogo: Fortnite');
assert(indexHtml.includes('Free Fire'), 'Jogo: Free Fire');
assert(indexHtml.includes('COD Mobile'), 'Jogo: COD Mobile');
assert(indexHtml.includes('Valorant'), 'Jogo: Valorant');

// Speedtest vs Lagcheck
assert(indexHtml.includes('Speedtest'), 'Comparação: Speedtest');
assert(indexHtml.includes('Comportamento sob carga'), 'Comparação: Comportamento sob carga');
assert(indexHtml.includes('Por que estou com lag no jogo?'), 'FAQ: Dúvida lag');
assert(indexHtml.includes('Como saber se posso jogar ranked?'), 'FAQ: Dúvida ranked');
assert(indexHtml.includes('Speedtest mostra lag de verdade?'), 'FAQ: Dúvida speedtest');

// Form e Backend
assert(indexHtml.includes('action') === false || indexHtml.includes('novalidate'), 'Formulário: Validação assíncrona JS');
assert(indexHtml.includes('fetch(\'/v1/waitlist\''), 'Backend: Envio para endpoint POST /v1/waitlist');
assert(indexHtml.includes('15000'), 'Backend: Timeout de 15 segundos configurado');
assert(indexHtml.includes('localStorage.setItem(\'lagcheck.waitlist\''), 'Resiliência: Preserva inscrição no localStorage');
assert(indexHtml.includes('Não conseguimos confirmar sua inscrição agora. Seu e-mail ficou salvo neste navegador'), 'UX de falha: Preserva e-mail e orienta usuário');

// UX Mobile & Desktop
assert(indexHtml.includes('class="mobile-cta"'), 'UX Mobile: CTA fixo mobile');
assert(indexHtml.includes('class="side"'), 'UX Desktop: Navegação lateral presente');

console.log('\n--- 5. Verificação das Páginas Auxiliares de Suporte e Privacidade ---');
const supportHtml = fs.readFileSync(path.join(WEB_DIR, 'support.html'), 'utf-8');
const privacyHtml = fs.readFileSync(path.join(WEB_DIR, 'privacy.html'), 'utf-8');

assert(supportHtml.includes('suporte@signallq.com'), 'Suporte: E-mail suporte@signallq.com presente');
assert(supportHtml.includes('TestFlight'), 'Suporte: Menção a TestFlight');
assert(supportHtml.includes('Play Beta'), 'Suporte: Menção a Play Beta');
assert(privacyHtml.includes('suporte@signallq.com'), 'Privacidade: E-mail suporte@signallq.com presente');
assert(privacyHtml.includes('Armazenamento local'), 'Privacidade: Seção de armazenamento local');

console.log('\n--- 6. Teste de Servidor HTTP Local (Rotas Estáticas) ---');
const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
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

const PORT = 8189;
server.listen(PORT, async () => {
  const routes = [
    '/',
    '/index.html',
    '/support.html',
    '/support/',
    '/support/index.html',
    '/privacy.html',
    '/privacy/',
    '/privacy/index.html',
    '/css/style.css',
    '/assets/lagcheck-wordmark-light.svg',
    '/Screenshot-iPhone-17-Pro-27-09-2026-at-19.05.37.png',
    '/Screenshot-iPhone-17-Pro-27-09-2026-at-19.05.13.png',
    '/robots.txt',
    '/sitemap.xml',
    '/og.png',
    '/favicon.ico',
    '/favicon.svg',
    '/apple-touch-icon.png',
    '/assets/app-home.webp',
    '/assets/app-games.webp'
  ];

  for (const route of routes) {
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

  if (typeof server.closeAllConnections === 'function') {
    server.closeAllConnections();
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
