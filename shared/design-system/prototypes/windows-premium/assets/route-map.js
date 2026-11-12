(function () {
  const REG = {
    'sa-east-1': [-23.55, -46.63], 'us-east-1': [38.95, -77.45], 'us-east-2': [39.96, -83.0], 'us-west-1': [37.34, -121.89], 'us-west-2': [45.52, -122.68],
    'ca-central-1': [45.42, -75.7], 'eu-central-1': [50.11, 8.68], 'eu-west-1': [53.35, -6.26], 'eu-west-2': [51.51, -0.13], 'eu-west-3': [48.86, 2.35],
    'eu-north-1': [59.33, 18.07], 'eu-south-1': [45.46, 9.19], 'ap-northeast-1': [35.68, 139.69], 'ap-northeast-2': [37.57, 126.98], 'ap-northeast-3': [34.69, 135.5],
    'ap-southeast-1': [1.35, 103.82], 'ap-southeast-2': [-33.87, 151.21], 'ap-south-1': [19.08, 72.88], 'ap-east-1': [22.32, 114.17], 'me-south-1': [26.22, 50.59], 'af-south-1': [-33.92, 18.42]
  };
  const NAMES = { 'sa-east-1': 'São Paulo', 'us-east-1': 'Virgínia', 'us-east-2': 'Ohio', 'us-west-1': 'Califórnia', 'us-west-2': 'Oregon', 'ca-central-1': 'Canadá', 'eu-central-1': 'Frankfurt', 'eu-west-1': 'Irlanda', 'eu-west-2': 'Londres', 'eu-west-3': 'Paris', 'eu-north-1': 'Estocolmo', 'eu-south-1': 'Milão', 'ap-northeast-1': 'Tóquio', 'ap-northeast-2': 'Seul', 'ap-northeast-3': 'Osaka', 'ap-southeast-1': 'Singapura', 'ap-southeast-2': 'Sydney', 'ap-south-1': 'Mumbai', 'ap-east-1': 'Hong Kong', 'me-south-1': 'Bahrein', 'af-south-1': 'Cidade do Cabo' };
  const pt = (id) => ({ lat: REG[id][0], lon: REG[id][1] });
  const proj = (lat, lon, c, w, h) => { const k = (w / 360) * c.zoom; return { x: w / 2 + (lon - c.lon) * k, y: h / 2 - (lat - c.lat) * k }; };
  const WORLD = { lon: 0, lat: 12, zoom: 1 };
  function fit(points, w, h, pad, maxZoom) {
    maxZoom = maxZoom || 7;
    if (!points.length || w <= 0 || h <= 0) return WORLD;
    const lons = points.map((p) => p.lon), lats = points.map((p) => p.lat);
    const ls = Math.max(Math.max(...lons) - Math.min(...lons), 8), as = Math.max(Math.max(...lats) - Math.min(...lats), 5);
    const ax = Math.max(w - pad.x * 2, 20), ay = Math.max(h - pad.y * 2, 20);
    const zoom = Math.min(maxZoom, Math.max(1, Math.min((ax * 360) / (w * ls), (ay * 360) / (w * as))));
    return { lon: (Math.max(...lons) + Math.min(...lons)) / 2, lat: (Math.max(...lats) + Math.min(...lats)) / 2, zoom };
  }
  function arcOf(p0, p1, maxH) {
    const dx = p1.x - p0.x, dy = p1.y - p0.y, d = Math.max(Math.hypot(dx, dy), 1), hh = Math.min(Math.max(d * 0.3, 24), maxH || 170);
    let nx = -dy / d, ny = dx / d;
    if (ny > 0) { nx = -nx; ny = -ny; }
    return { x0: p0.x, y0: p0.y, x1: p1.x, y1: p1.y, cx: (p0.x + p1.x) / 2 + nx * hh, cy: (p0.y + p1.y) / 2 + ny * hh };
  }
  const bez = (a, t) => { const c = Math.min(Math.max(t, 0), 1), u = 1 - c; return { x: u * u * a.x0 + 2 * u * c * a.cx + c * c * a.x1, y: u * u * a.y0 + 2 * u * c * a.cy + c * c * a.y1 }; };
  const ease = (t) => { const c = Math.min(Math.max(t, 0), 1); return c < 0.5 ? 4 * c * c * c : 1 - Math.pow(-2 * c + 2, 3) / 2; };
  const retMs = (r) => Math.min(Math.max(r * 8, 300), 700);
  const overlaps = (a, b) => a.x < b.x + b.w + 4 && a.x + a.w + 4 > b.x && a.y < b.y + b.h + 4 && a.y + a.h + 4 > b.y;
  let gridP = null;
  function loadGrid() {
    gridP = gridP || fetch('assets/map-grid.json').then((r) => r.json()).then((raw) => {
      const lons = [], lats = [];
      raw.grid.forEach((line, r) => { const lat = raw.latTop - (r + 0.5) * raw.step; for (let c = 0; c < line.length; c++) if (line.charCodeAt(c) === 49) { lons.push(-180 + (c + 0.5) * raw.step); lats.push(lat); } });
      return { lons, lats, step: raw.step };
    });
    return gridP;
  }
  const PAL = { deep: '#0b0d10', land: 'rgba(138,147,160,0.34)', region: '#8a93a0', muted: '#606873', purple: '#7c3aed', purpleLight: '#a78bfa', text: '#f4f5f7', body: "'Segoe UI Variable Text','Segoe UI',system-ui,sans-serif", metric: "'Chakra Petch','Cascadia Mono',monospace" };

  class RouteMap {
    constructor(host, o) {
      this.host = host; this.o = o || {}; this.animate = this.o.animate !== false;
      this.canvas = document.createElement('canvas');
      this.canvas.style.cssText = 'position:absolute;inset:0;width:100%;height:100%;display:block';
      host.appendChild(this.canvas); this.ctx = this.canvas.getContext('2d');
      this.user = null; this.selId = null; this.selMs = null; this.regions = new Map(); this.packets = []; this.sweepWanted = false; this.raf = 0; this.last = 0; this.dead = false; this.grid = null;
      this.resize();
      if (window.ResizeObserver) { this.ro = new ResizeObserver(() => { this.resize(); if (!this.animate) this.cam = this.target(); this.schedule(); }); this.ro.observe(host); }
      loadGrid().then((g) => { this.grid = g; this.schedule(); });
      this.cam = this.target(); this.schedule();
    }
    resize() { const r = this.host.getBoundingClientRect(); this.dpr = Math.min(window.devicePixelRatio || 1, 2); this.w = Math.round(r.width); this.h = Math.round(r.height); this.canvas.width = Math.max(Math.round(this.w * this.dpr), 1); this.canvas.height = Math.max(Math.round(this.h * this.dpr), 1); }
    setUser(u) { this.user = u; this.retarget(); this.trySweep(); }
    reset() { this.selId = null; this.selMs = null; this.regions = new Map(); this.packets = []; this.sweepWanted = false; this.retarget(); }
    regionSample(id, ms) {
      if (!REG[id]) return;
      const s = this.regions.get(id) || { ms: null, ok: false, n: 0 }; s.n++;
      if (ms != null) { s.ok = true; s.ms = s.ms == null ? ms : Math.min(s.ms, ms); }
      this.regions.set(id, s);
      if (this.animate && this.user && !this.selId) {
        const now = performance.now();
        if (ms != null && this.packets.length < 80) this.packets.push({ id, sweep: true, ph: 'in', start: now, dur: retMs(ms), rtt: ms });
        if (s.n < 4 && this.packets.length < 80) this.packets.push({ id, sweep: true, ph: 'out', start: now, dur: 620, rtt: 0 });
      }
      this.schedule();
    }
    selectRegion(id, ms) { if (!REG[id]) return; this.selId = id; this.sweepWanted = false; this.packets = this.packets.filter((p) => !p.sweep); this.selMs = ms != null ? ms : (this.regions.get(id) || {}).ms || this.selMs; this.retarget(); }
    probe(rtt) { if (!this.animate || !this.user || !this.selId || this.packets.length >= 6) return; this.packets.push({ id: this.selId, sweep: false, ph: 'out', start: performance.now(), dur: 420, rtt }); this.schedule(); }
    startSweep() { this.sweepWanted = true; this.trySweep(); }
    trySweep() {
      if (!this.animate || !this.sweepWanted || this.selId || !this.user) return;
      this.sweepWanted = false; const t0 = performance.now();
      Object.keys(REG).forEach((id, i) => this.packets.push({ id, sweep: true, ph: 'out', start: t0 + i * 45, dur: 620, rtt: 0 }));
      this.schedule();
    }
    destroy() { this.dead = true; cancelAnimationFrame(this.raf); this.ro && this.ro.disconnect(); this.canvas.remove(); }
    retarget() { if (!this.animate) this.cam = this.target(); this.schedule(); }
    target() {
      const sel = this.selId ? pt(this.selId) : null;
      if (sel) return fit(this.user ? [this.user, sel] : [sel], this.w, this.h, { x: Math.min(110, this.w * 0.2), y: 52 }, 3.4);
      const pts = Object.keys(REG).map(pt); if (this.user) pts.push(this.user);
      return fit(pts, this.w, this.h, { x: 28, y: 28 });
    }
    schedule() { if (this.dead || this.raf) return; this.raf = requestAnimationFrame((t) => this.frame(t)); }
    frame(now) {
      this.raf = 0; if (this.dead) return;
      const tg = this.target(), dt = this.last ? Math.min((now - this.last) / 1000, 0.05) : 0.016; this.last = now;
      if (this.animate) { const k = 1 - Math.exp(-dt * 3.2); this.cam = { lon: this.cam.lon + (tg.lon - this.cam.lon) * k, lat: this.cam.lat + (tg.lat - this.cam.lat) * k, zoom: this.cam.zoom + (tg.zoom - this.cam.zoom) * k }; } else this.cam = tg;
      const pn = performance.now();
      for (let i = this.packets.length - 1; i >= 0; i--) {
        const p = this.packets[i]; if (pn < p.start || pn - p.start < p.dur) continue;
        if (p.sweep) this.packets.splice(i, 1);
        else if (p.ph === 'out') { p.ph = 'in'; p.start = pn; p.dur = retMs(p.rtt); } else this.packets.splice(i, 1);
      }
      this.draw(pn);
      const settled = Math.abs(tg.lon - this.cam.lon) < 0.01 && Math.abs(tg.lat - this.cam.lat) < 0.01 && Math.abs(tg.zoom - this.cam.zoom) < 0.002;
      if (this.animate && (!settled || this.packets.length)) this.raf = requestAnimationFrame((t) => this.frame(t)); else this.last = 0;
    }
    draw(now) {
      const ctx = this.ctx, w = this.w, h = this.h, cam = this.cam; if (!ctx || !w || !h) return;
      ctx.setTransform(this.dpr, 0, 0, this.dpr, 0, 0); ctx.fillStyle = PAL.deep; ctx.fillRect(0, 0, w, h);
      if (this.grid) {
        const k = (w / 360) * cam.zoom, r = Math.min(Math.max(k * this.grid.step * 0.34, 0.8), 3.4);
        ctx.fillStyle = PAL.land; ctx.beginPath();
        for (let i = 0; i < this.grid.lons.length; i++) { const p = proj(this.grid.lats[i], this.grid.lons[i], cam, w, h); if (p.x < -r || p.x > w + r || p.y < -r || p.y > h + r) continue; ctx.moveTo(p.x + r, p.y); ctx.arc(p.x, p.y, r, 0, Math.PI * 2); }
        ctx.fill();
      }
      const sg = this.selId ? pt(this.selId) : null;
      const up = this.user ? proj(this.user.lat, this.user.lon, cam, w, h) : null, sp = sg ? proj(sg.lat, sg.lon, cam, w, h) : null;
      let leader = null;
      if (!this.selId) { let b = Infinity; this.regions.forEach((s, id) => { if (s.ms != null && s.ms < b) { b = s.ms; leader = id; } }); }
      Object.keys(REG).forEach((id) => {
        if (id === this.selId) return; const g = pt(id), p = proj(g.lat, g.lon, cam, w, h), s = this.regions.get(id); ctx.beginPath();
        if (id === leader) { ctx.fillStyle = PAL.purpleLight; ctx.arc(p.x, p.y, 4.2, 0, 6.283); ctx.fill(); }
        else if (s && s.ok) { ctx.fillStyle = PAL.region; ctx.arc(p.x, p.y, 2.8, 0, 6.283); ctx.fill(); }
        else { ctx.strokeStyle = PAL.muted; ctx.lineWidth = 1.2; ctx.arc(p.x, p.y, 2.8, 0, 6.283); ctx.stroke(); }
      });
      if (up && sp) {
        const a = arcOf(up, sp, h * 0.38); ctx.strokeStyle = PAL.purple; ctx.lineWidth = 1.6; ctx.beginPath(); ctx.moveTo(a.x0, a.y0); ctx.quadraticCurveTo(a.cx, a.cy, a.x1, a.y1); ctx.stroke();
        this.packets.forEach((pk) => { if (pk.sweep || now < pk.start) return; const t = ease(Math.min((now - pk.start) / pk.dur, 1)), pos = bez(a, pk.ph === 'out' ? t : 1 - t); ctx.fillStyle = pk.ph === 'out' ? PAL.purpleLight : PAL.text; ctx.beginPath(); ctx.arc(pos.x, pos.y, 3.2, 0, 6.283); ctx.fill(); });
      }
      if (up && !sp) {
        ctx.lineWidth = 1;
        this.packets.forEach((pk) => {
          if (!pk.sweep || now < pk.start) return; const g = pt(pk.id), rp = proj(g.lat, g.lon, cam, w, h), a = arcOf(up, rp, h * 0.38), t = ease(Math.min((now - pk.start) / pk.dur, 1));
          ctx.strokeStyle = 'rgba(167,139,250,0.22)'; ctx.beginPath(); ctx.moveTo(a.x0, a.y0); ctx.quadraticCurveTo(a.cx, a.cy, a.x1, a.y1); ctx.stroke();
          const pos = bez(a, pk.ph === 'out' ? t : 1 - t); ctx.fillStyle = pk.ph === 'out' ? PAL.purpleLight : PAL.text; ctx.beginPath(); ctx.arc(pos.x, pos.y, 2.6, 0, 6.283); ctx.fill();
        });
      }
      if (sp) { ctx.fillStyle = PAL.purple; ctx.strokeStyle = PAL.deep; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(sp.x, sp.y, 5.6, 0, 6.283); ctx.fill(); ctx.stroke(); }
      if (up) { ctx.fillStyle = PAL.text; ctx.strokeStyle = PAL.deep; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(up.x, up.y, 5, 0, 6.283); ctx.fill(); ctx.stroke(); }
      const placed = [];
      if (up && this.user) placed.push(this.label(ctx, up, 'above', [{ t: this.user.city ? 'Você · ' + this.user.city : 'Você', f: 'body', c: PAL.text }], placed));
      const lid = this.selId || leader, lp = sp || (leader ? (() => { const g = pt(leader); return proj(g.lat, g.lon, cam, w, h); })() : null);
      if (lid && lp) {
        const ms = this.selId ? this.selMs : (this.regions.get(lid) || {}).ms;
        const runs = [{ t: NAMES[lid], f: 'body', c: PAL.text }]; if (ms != null) runs.push({ t: ' · ' + Math.round(ms) + ' ms', f: 'metric', c: PAL.purpleLight });
        placed.push(this.label(ctx, lp, 'below', runs, placed));
      }
    }
    label(ctx, an, side, runs, others) {
      const font = (f) => (f === 'metric' ? '600 12px ' + PAL.metric : '600 12px ' + PAL.body); let tw = 0;
      runs.forEach((r) => { ctx.font = font(r.f); tw += ctx.measureText(r.t).width; });
      const bx = { x: 0, y: 0, w: tw + 16, h: 24 };
      const place = (s) => { bx.x = Math.min(Math.max(an.x - bx.w / 2, 4), Math.max(this.w - bx.w - 4, 4)); bx.y = s === 'above' ? an.y - 12 - bx.h : an.y + 12; bx.y = Math.min(Math.max(bx.y, 4), Math.max(this.h - bx.h - 4, 4)); };
      place(side); if (others.some((o) => overlaps(bx, o))) place(side === 'above' ? 'below' : 'above');
      if (others.some((o) => overlaps(bx, o))) { const o = others.find((q) => overlaps(bx, q)); bx.x = o.x + o.w + 6 + bx.w <= this.w - 4 ? o.x + o.w + 6 : Math.max(o.x - bx.w - 6, 4); }
      ctx.fillStyle = 'rgba(11,13,16,0.9)'; ctx.strokeStyle = 'rgba(244,245,247,0.16)'; ctx.lineWidth = 1;
      const x = bx.x + 0.5, y = bx.y + 0.5, w = bx.w - 1, h = bx.h - 1, r = 6;
      ctx.beginPath(); ctx.moveTo(x + r, y); ctx.arcTo(x + w, y, x + w, y + h, r); ctx.arcTo(x + w, y + h, x, y + h, r); ctx.arcTo(x, y + h, x, y, r); ctx.arcTo(x, y, x + w, y, r); ctx.closePath(); ctx.fill(); ctx.stroke();
      ctx.textBaseline = 'middle'; let tx = bx.x + 8;
      runs.forEach((r2) => { ctx.font = font(r2.f); ctx.fillStyle = r2.c; ctx.fillText(r2.t, tx, bx.y + bx.h / 2 + 0.5); tx += ctx.measureText(r2.t).width; });
      return { x: bx.x, y: bx.y, w: bx.w, h: bx.h };
    }
  }
  window.RouteMap = RouteMap; window.LC_REGIONS = REG; window.LC_NAMES = NAMES;
})();
