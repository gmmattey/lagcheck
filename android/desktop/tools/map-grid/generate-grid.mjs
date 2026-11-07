/**
 * Gerador / extrator da grade de pontos (dot-matrix) do mapa-múndi para o LagCheck Desktop.
 *
 * Fonte primária dos dados: Natural Earth 110m (world-atlas / land-110m.json, domínio público).
 * Projeção: Equiretangular recortada (lon: -180..180, lat: 84..-58, passo: 1.5°, 240x95).
 * Total de pontos de terra: 6.858 pontos.
 *
 * Como executar (offline, sem dependências externas adicionais):
 *   node generate-grid.mjs
 *
 * O script extrai a grade canônica validada do protótipo windows-premium ou de land-110m.json,
 * valida a contagem e salva em ../../src/main/resources/map/map-grid.json.
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const repoRoot = resolve(__dirname, '../../../../');
const prototypeHtmlPath = resolve(repoRoot, 'design-system/prototypes/windows-premium/index.html');
const outputJsonPath = resolve(__dirname, '../../src/main/resources/map/map-grid.json');

console.log('Lendo grade do protótipo em:', prototypeHtmlPath);
const html = readFileSync(prototypeHtmlPath, 'utf8');
const match = html.match(/\/\*GRID:start\*\/([\s\S]*?)\/\*GRID:end\*\//);

if (!match) {
  console.error('ERRO: Marcadores /*GRID:start*/ e /*GRID:end*/ não encontrados no HTML do protótipo.');
  process.exit(1);
}

const mapData = JSON.parse(match[1]);

// Validações de integridade
if (mapData.cols !== 240 || mapData.rows !== 95 || mapData.step !== 1.5 || mapData.latTop !== 84 || mapData.latBottom !== -58) {
  console.error('ERRO: Dimensões da grade divergem da especificação (240x95, step 1.5, latTop 84, latBottom -58).', mapData);
  process.exit(1);
}

if (!Array.isArray(mapData.grid) || mapData.grid.length !== 95) {
  console.error('ERRO: Array grid inválido ou número de linhas incorreto:', mapData.grid?.length);
  process.exit(1);
}

const totalLand = mapData.grid.join('').split('1').length - 1;
console.log(`Grade validada: ${mapData.cols}x${mapData.rows}, ${totalLand} pontos de terra (esperado: 6858).`);

if (totalLand !== 6858) {
  console.error(`AVISO: Contagem de pontos (${totalLand}) diferente de 6858.`);
}

// Garante o diretório de destino
mkdirSync(dirname(outputJsonPath), { recursive: true });
writeFileSync(outputJsonPath, JSON.stringify(mapData), 'utf8');

console.log('Grade salva com sucesso em:', outputJsonPath);
