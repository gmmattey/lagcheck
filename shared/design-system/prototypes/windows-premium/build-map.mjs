// Gera a grade de pontos (dot-matrix) do mapa-múndi e injeta em index.html.
// Fonte: Natural Earth 110m via world-atlas (domínio público). Sem dependência em runtime.
// Uso (numa pasta com as deps): npm i d3-geo topojson-client world-atlas && node build-map.mjs [caminho/index.html]
// Projeção equiretangular recortada: lon -180..180, lat 84..-58. O runtime do protótipo repete a mesma conta.
import { readFileSync, writeFileSync } from 'node:fs'
import { geoContains } from 'd3-geo'
import { feature } from 'topojson-client'

const target = process.argv[2] ?? new URL('./index.html', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1')
const topo = JSON.parse(readFileSync('./node_modules/world-atlas/land-110m.json', 'utf8'))
const land = feature(topo, topo.objects.land)
const STEP = 1.5, LAT_TOP = 84, LAT_BOTTOM = -58
const cols = Math.round(360 / STEP), rows = Math.round((LAT_TOP - LAT_BOTTOM) / STEP)
const grid = []
for (let r = 0; r < rows; r++) {
  const lat = LAT_TOP - (r + 0.5) * STEP
  let line = ''
  for (let c = 0; c < cols; c++) line += geoContains(land, [-180 + (c + 0.5) * STEP, lat]) ? '1' : '0'
  grid.push(line)
}
const data = JSON.stringify({ step: STEP, latTop: LAT_TOP, latBottom: LAT_BOTTOM, cols, rows, grid })
const html = readFileSync(target, 'utf8')
const out = html.replace(/\/\*GRID:start\*\/[\s\S]*?\/\*GRID:end\*\//, () => `/*GRID:start*/${data}/*GRID:end*/`)
if (out === html) throw new Error('marcadores GRID não encontrados')
writeFileSync(target, out)
console.log(`ok: ${grid.join('').split('1').length - 1} pontos de terra → ${target}`)
