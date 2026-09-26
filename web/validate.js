/**
 * Nolaggy — Static Site Automated Validation Suite
 * Validação rigorosa dos arquivos do site estático em web/ sem dependências externas.
 */

const fs = require('fs');
const path = require('path');
const http = require('http');

const WEB_DIR = path.resolve(__dirname);
const REPO_ROOT = path.resolve(WEB_DIR, '..');

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

console.log('\n--- 1. Verificação de Estrutura de Arquivos ---');
const requiredFiles = [
  'index.html',
  'support.html',
  'support/index.html',
  'privacy.html',
  'privacy/index.html',
  'css/style.css',
  'js/main.js',
  'assets/brand/app-icon-source.svg',
  'assets/brand/lockup-thumbnail.svg',
  'assets/brand/symbol-compact.svg',
  'assets/brand/wordmark-mono-dark.svg',
  'assets/brand/wordmark-mono-light.svg',
  'assets/brand/wordmark-primary.svg',
  'robots.txt',
  'sitemap.xml',
  'README.md'
];

requiredFiles.forEach((relPath) => {
  const fullPath = path.join(WEB_DIR, relPath);
  assert(fs.existsSync(fullPath), `Arquivo existe: ${relPath}`);
});

console.log('\n--- 2. Verificação de Integridade dos Ativos Oficiais ---');
const officialBrandDir = path.join(REPO_ROOT, 'design-system', 'assets', 'brand');
const webBrandDir = path.join(WEB_DIR, 'assets', 'brand');

const brandSVGs = [
  'app-icon-source.svg',
  'lockup-thumbnail.svg',
  'symbol-compact.svg',
  'wordmark-mono-dark.svg',
  'wordmark-mono-light.svg',
  'wordmark-primary.svg'
];

brandSVGs.forEach((svgName) => {
  const src = fs.readFileSync(path.join(officialBrandDir, svgName));
  const dest = fs.readFileSync(path.join(webBrandDir, svgName));
  assert(src.equals(dest), `Ativo ${svgName} é 100% idêntico ao oficial`);
});

console.log('\n--- 3. Verificação de Tokens de Design System em style.css ---');
const cssContent = fs.readFileSync(path.join(WEB_DIR, 'css', 'style.css'), 'utf-8');
const expectedTokens = [
  '--navy-950: #040A16;',
  '--navy-900: #050B18;',
  '--navy-800: #0A1730;',
  '--navy-700: #101E3D;',
  '--blue-500: #2E7CFF;',
  '--green-500: #3DDC97;',
  '--amber-500: #F5B942;',
  '--coral-500: #F0525B;',
  '--neutral-50: #F5F8FF;',
  '--neutral-400: #AAB4CC;',
  '--neutral-900: #1C2A4A;'
];

expectedTokens.forEach((token) => {
  assert(cssContent.includes(token), `Token presente em style.css: ${token}`);
});

console.log('\n--- 4. Verificação de Conteúdo e Requisitos de Negócio ---');
const htmlFiles = ['index.html', 'support.html', 'privacy.html'];

htmlFiles.forEach((file) => {
  const content = fs.readFileSync(path.join(WEB_DIR, file), 'utf-8');

  // Wordmark em minúsculas
  assert(content.includes('alt="lagcheck"'), `${file}: Wordmark usa 'lagcheck' em minúsculas`);

  // Plataforma iPhone e iOS 17+
  assert(content.includes('iPhone') && content.includes('iOS 17'), `${file}: Especifica iPhone e iOS 17+`);

  // Não promete ping real
  assert(
    content.includes('não promete o ping real') || content.includes('sem falsas promessas de ping') || content.includes('does not promise'),
    `${file}: Declara expressamente que não promete ping real de jogos`
  );

  // Skip link acessível
  assert(content.includes('class="skip-link"'), `${file}: Possui skip link acessível`);

  // Botão de alternância de idioma
  assert(content.includes('class="lang-toggle"'), `${file}: Possui controle de idioma acessível`);

  // Paridade de blocos bilíngues (PT-BR e EN)
  const ptCount = (content.match(/data-lang="pt"/g) || []).length;
  const enCount = (content.match(/data-lang="en"/g) || []).length;
  assert(ptCount > 0 && ptCount === enCount, `${file}: Paridade de tradução (${ptCount} blocos PT / ${enCount} blocos EN)`);
});

// Verificações específicas da Política de Privacidade
const privacyContent = fs.readFileSync(path.join(WEB_DIR, 'privacy.html'), 'utf-8');
const privacyRequirements = [
  { text: 'sem contas', desc: 'Sem necessidade de conta/cadastro' },
  { text: 'telemetria própria', desc: 'Sem telemetria própria' },
  { text: 'SwiftData', desc: 'Armazenamento local no iPhone via SwiftData' },
  { text: '90 dias', desc: 'Retenção máxima de 90 dias' },
  { text: '100', desc: 'Limite de até 100 registros recentes por jogo' },
  { text: 'GET /v1/load', desc: 'Endpoint de carga controlada Deep Check' },
  { text: 'Cache-Control: no-store', desc: 'Cabeçalho no-store no Deep Check' },
  { text: 'não identifica', desc: 'Worker sem identificação de pessoa, aparelho ou sessão' },
  { text: 'não estão integrados nem ativos', desc: 'AdMob e UMP explicitamente não integrados/inativos' },
  { text: 'formalmente revisada', desc: 'Compromisso de revisão formal antes de integrar AdMob/UMP ou catálogo remoto' }
];

privacyRequirements.forEach((req) => {
  assert(privacyContent.includes(req.text), `privacy.html: ${req.desc}`);
});

// Verificações específicas do Suporte
const supportContent = fs.readFileSync(path.join(WEB_DIR, 'support.html'), 'utf-8');
const supportRequirements = [
  { text: 'suporte@lagcheck.app', desc: 'Contato de suporte visível' },
  { text: 'provisório', desc: 'Contato provisório explicitamente identificado' },
  { text: 'Metodologia do LagCheck', desc: 'Explicação da metodologia do LagCheck' },
  { text: 'consentimento', desc: 'Consentimento de dados em rede móvel' },
  { text: 'Inconclusivo', desc: 'Tratamento honesto de resultado inconclusivo' },
  { text: '75 – 100', desc: 'Tabela com escala do LagCheck Score' }
];

supportRequirements.forEach((req) => {
  assert(supportContent.includes(req.text), `support.html: ${req.desc}`);
});

console.log('\n--- 5. Teste de Servidor HTTP Local ---');
const server = http.createServer((req, res) => {
  let reqPath = req.url.split('?')[0];
  if (reqPath === '/') reqPath = '/index.html';

  let filePath = path.join(WEB_DIR, reqPath);
  if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
    filePath = path.join(filePath, 'index.html');
  }

  if (fs.existsSync(filePath)) {
    const ext = path.extname(filePath);
    const contentTypes = {
      '.html': 'text/html; charset=utf-8',
      '.css': 'text/css; charset=utf-8',
      '.js': 'application/javascript; charset=utf-8',
      '.svg': 'image/svg+xml',
      '.xml': 'application/xml; charset=utf-8',
      '.txt': 'text/plain; charset=utf-8'
    };
    res.writeHead(200, { 'Content-Type': contentTypes[ext] || 'application/octet-stream' });
    res.end(fs.readFileSync(filePath));
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});

server.listen(0, '127.0.0.1', async () => {
  const port = server.address().port;
  const baseUrl = `http://127.0.0.1:${port}`;

  const routesToTest = [
    '/',
    '/index.html',
    '/support.html',
    '/support/',
    '/support/index.html',
    '/privacy.html',
    '/privacy/',
    '/privacy/index.html',
    '/css/style.css',
    '/js/main.js',
    '/assets/brand/wordmark-primary.svg',
    '/assets/brand/symbol-compact.svg',
    '/robots.txt',
    '/sitemap.xml'
  ];

  for (const route of routesToTest) {
    await new Promise((resolve) => {
      http.get(`${baseUrl}${route}`, (res) => {
        assert(res.statusCode === 200, `Rota HTTP ${route} responde com status 200`);
        resolve();
      }).on('error', (err) => {
        assert(false, `Erro ao acessar ${route}: ${err.message}`);
        resolve();
      });
    });
  }

  server.close(() => {
    console.log('\n========================================');
    console.log(`Resumo dos Testes: ${passedTests}/${totalTests} passaram`);
    if (failedTests > 0) {
      console.error(`Status: ${failedTests} testes falharam!`);
      process.exit(1);
    } else {
      console.log('Status: Todos os testes passaram com sucesso! ✓');
      process.exit(0);
    }
  });
});
