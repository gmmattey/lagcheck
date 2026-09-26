/**
 * Nolaggy — Main Client Script
 * Gerencia controle de idioma (PT-BR / EN), persistência em localStorage e acessibilidade.
 */

(function () {
  'use strict';

  const STORAGE_KEY = 'nolaggy_preferred_language';

  // Detect initial language
  function getInitialLanguage() {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored === 'pt' || stored === 'en') {
        return stored;
      }
    } catch (e) {
      // Ignore localStorage security/private mode errors
    }

    const browserLang = (navigator.language || navigator.userLanguage || '').toLowerCase();
    if (browserLang.startsWith('en')) {
      return 'en';
    }
    return 'pt';
  }

  // Apply language to DOM
  function applyLanguage(lang) {
    const isEn = lang === 'en';
    const targetLang = isEn ? 'en' : 'pt';
    const htmlLang = isEn ? 'en' : 'pt-BR';

    document.documentElement.lang = htmlLang;

    if (document.body) {
      document.body.classList.remove('lang-pt', 'lang-en');
      document.body.classList.add(`lang-${targetLang}`);
    }

    // Update toggle buttons
    const toggles = document.querySelectorAll('.lang-toggle');
    toggles.forEach((toggle) => {
      toggle.setAttribute('aria-label', isEn ? 'Mudar para Português' : 'Switch to English');
      toggle.setAttribute('aria-pressed', isEn ? 'true' : 'false');

      const ptBadge = toggle.querySelector('.lang-badge-pt');
      const enBadge = toggle.querySelector('.lang-badge-en');
      if (ptBadge && enBadge) {
        if (isEn) {
          ptBadge.classList.remove('active');
          enBadge.classList.add('active');
        } else {
          ptBadge.classList.add('active');
          enBadge.classList.remove('active');
        }
      }
    });

    try {
      localStorage.setItem(STORAGE_KEY, targetLang);
    } catch (e) {
      // Ignore storage errors
    }

    // Dispatch event for any reactive listeners
    window.dispatchEvent(new CustomEvent('nolaggy:langchange', { detail: { lang: targetLang } }));
  }

  // Toggle between languages
  function toggleLanguage() {
    const current = document.body.classList.contains('lang-en') ? 'en' : 'pt';
    const next = current === 'pt' ? 'en' : 'pt';
    applyLanguage(next);
  }

  // Init when DOM is ready
  function init() {
    const initialLang = getInitialLanguage();
    applyLanguage(initialLang);

    // Bind event listeners to all language toggles
    document.querySelectorAll('.lang-toggle').forEach((btn) => {
      btn.addEventListener('click', (e) => {
        e.preventDefault();
        toggleLanguage();
      });
    });

  // Highlight current page in navigation
    const currentPath = window.location.pathname;
    document.querySelectorAll('.site-header .nav-link').forEach((link) => {
      const href = link.getAttribute('href');
      if (href && (currentPath.endsWith(href) || (href === '/' && currentPath.endsWith('/index.html')))) {
        link.classList.add('active');
      }
    });

    // Initialize Interactive Route Simulator if present
    initSimulator();
  }

  // --- Interactive Route & Readiness Simulator ---
  const GAME_DATA = {
    valorant: {
      name: 'Valorant',
      publisher: 'Riot Games',
      image: 'assets/games/valorant.jpg',
      regions: {
        'sa-east-1': { location: 'São Paulo (BR1)', ping: 18, jitter: 1.1, loss: 0.0, verdict: 'ready', verdictPt: 'PRONTO PARA RANKED', verdictEn: 'READY FOR RANKED', descPt: 'Rota ultrarrápida direta ao cluster Riot BR1 com jitter imperceptível.', descEn: 'Direct ultra-fast route to Riot BR1 cluster with imperceptible jitter.' },
        'us-east-1': { location: 'Virgínia (NA-East)', ping: 118, jitter: 3.2, loss: 0.2, verdict: 'warn', verdictPt: 'EU EVITARIA RANKED AGORA', verdictEn: 'AVOID RANKED RIGHT NOW', descPt: 'Latência intercontinental elevada para trocas rápidas de tiro.', descEn: 'High cross-border latency for twitch aim and peeking.' },
        'eu-central-1': { location: 'Frankfurt (EU)', ping: 186, jitter: 5.4, loss: 0.5, verdict: 'bad', verdictPt: 'CONDIÇÕES INSTÁVEIS', verdictEn: 'UNSTABLE CONDITIONS', descPt: 'Distância transatlântica com atraso severo nos registros.', descEn: 'Transatlantic distance with severe bullet registration delay.' }
      }
    },
    cs2: {
      name: 'Counter-Strike 2',
      publisher: 'Valve',
      image: 'assets/games/cs2.jpg',
      regions: {
        'sa-east-1': { location: 'São Paulo (GRU)', ping: 15, jitter: 0.9, loss: 0.0, verdict: 'ready', verdictPt: 'PRONTO PARA RANKED', verdictEn: 'READY FOR RANKED', descPt: 'Sub-tick ideal com socket UDP Valve direto sem atraso de interpolação.', descEn: 'Ideal sub-tick with direct Valve UDP socket without interpolation lag.' },
        'us-east-1': { location: 'Virgínia (US)', ping: 122, jitter: 4.1, loss: 0.4, verdict: 'warn', verdictPt: 'EU EVITARIA RANKED AGORA', verdictEn: 'AVOID RANKED RIGHT NOW', descPt: 'Sub-tick penalizado por distância geográfica e rota com saltos extras.', descEn: 'Sub-tick compromised by distance and intermediate WAN hops.' },
        'eu-central-1': { location: 'Frankfurt (EU)', ping: 195, jitter: 6.8, loss: 1.0, verdict: 'bad', verdictPt: 'CONDIÇÕES INSTÁVEIS', verdictEn: 'UNSTABLE CONDITIONS', descPt: 'Descompasso crítico de tiro e perda esporádica de pacotes.', descEn: 'Critical hit registration desync and sporadic packet loss.' }
      }
    },
    lol: {
      name: 'League of Legends',
      publisher: 'Riot Games',
      image: 'assets/games/leagueoflegends.jpg',
      regions: {
        'sa-east-1': { location: 'São Paulo (BR1)', ping: 17, jitter: 1.0, loss: 0.0, verdict: 'ready', verdictPt: 'PRONTO PARA RANKED', verdictEn: 'READY FOR RANKED', descPt: 'Conexão estável para teamfights intensas e combos milimétricos.', descEn: 'Rock-solid connection for chaotic teamfights and precise combos.' },
        'us-east-1': { location: 'Chicago / Virgínia', ping: 128, jitter: 3.8, loss: 0.1, verdict: 'warn', verdictPt: 'EU EVITARIA RANKED AGORA', verdictEn: 'AVOID RANKED RIGHT NOW', descPt: 'Atraso em reações rápidas de Flash e esquivas de skillshots.', descEn: 'Lag on fast Flash reaction timings and skillshot dodges.' },
        'eu-central-1': { location: 'Frankfurt (EUW)', ping: 190, jitter: 7.2, loss: 0.8, verdict: 'bad', verdictPt: 'CONDIÇÕES INSTÁVEIS', verdictEn: 'UNSTABLE CONDITIONS', descPt: 'Atraso de comando perceptível e risco de desconnexão.', descEn: 'Noticeable command delay and disconnect risk.' }
      }
    },
    fortnite: {
      name: 'Fortnite',
      publisher: 'Epic Games / AWS',
      image: 'assets/games/fortnite.jpg',
      regions: {
        'sa-east-1': { location: 'São Paulo (sa-east-1)', ping: 21, jitter: 1.4, loss: 0.0, verdict: 'ready', verdictPt: 'PRONTO PARA RANKED', verdictEn: 'READY FOR RANKED', descPt: 'AWS GameLift direto com excelente resposta para construção rápida.', descEn: 'Direct AWS GameLift beacon with crisp responsiveness for fast building.' },
        'us-east-1': { location: 'Virgínia (us-east-1)', ping: 115, jitter: 3.5, loss: 0.1, verdict: 'warn', verdictPt: 'EU EVITARIA RANKED AGORA', verdictEn: 'AVOID RANKED RIGHT NOW', descPt: 'Atraso de substituição de paredes e edição de peças.', descEn: 'Delay on wall replacement and piece editing.' },
        'eu-central-1': { location: 'Frankfurt (eu-central-1)', ping: 182, jitter: 6.0, loss: 0.7, verdict: 'bad', verdictPt: 'CONDIÇÕES INSTÁVEIS', verdictEn: 'UNSTABLE CONDITIONS', descPt: 'Inviável para torneios competitivos ou arenas ranqueadas.', descEn: 'Unviable for competitive tournaments or ranked arenas.' }
      }
    },
    eafc: {
      name: 'EA Sports FC 25',
      publisher: 'EA Sports',
      image: 'assets/games/eafc.jpg',
      regions: {
        'sa-east-1': { location: 'São Paulo (EA Hub)', ping: 19, jitter: 1.2, loss: 0.0, verdict: 'ready', verdictPt: 'PRONTO PARA RANKED', verdictEn: 'READY FOR RANKED', descPt: 'Resposta imediata no passe, drible e divididas sem lentidão.', descEn: 'Immediate response in passing, dribbling, and tackles.' },
        'us-east-1': { location: 'Miami / Virgínia', ping: 120, jitter: 4.5, loss: 0.3, verdict: 'warn', verdictPt: 'EU EVITARIA RANKED AGORA', verdictEn: 'AVOID RANKED RIGHT NOW', descPt: 'Sensação pesada de controle nos jogadores e delay de chute.', descEn: 'Heavy player movement feeling and shooting input delay.' },
        'eu-central-1': { location: 'Frankfurt (EU)', ping: 192, jitter: 8.0, loss: 1.2, verdict: 'bad', verdictPt: 'CONDIÇÕES INSTÁVEIS', verdictEn: 'UNSTABLE CONDITIONS', descPt: 'Descompasso grave de animações e micro-travamentos.', descEn: 'Severe animation desynchronization and micro-stuttering.' }
      }
    },
    warzone: {
      name: 'CoD Warzone',
      publisher: 'Activision',
      image: 'assets/games/warzone.jpg',
      regions: {
        'sa-east-1': { location: 'São Paulo (Battle.net)', ping: 23, jitter: 1.6, loss: 0.0, verdict: 'ready', verdictPt: 'PRONTO PARA RANKED', verdictEn: 'READY FOR RANKED', descPt: 'Bufferbloat estável sob rajadas pesadas de tiros em battle royale.', descEn: 'Bufferbloat held stable under intense battle royale firefights.' },
        'us-east-1': { location: 'Virgínia (US)', ping: 125, jitter: 4.8, loss: 0.2, verdict: 'warn', verdictPt: 'EU EVITARIA RANKED AGORA', verdictEn: 'AVOID RANKED RIGHT NOW', descPt: 'Desvantagem de peeker e perda de cadência em confrontos curtos.', descEn: "Peeker's disadvantage and lost cadence in close quarters." },
        'eu-central-1': { location: 'Frankfurt (EU)', ping: 198, jitter: 9.1, loss: 1.5, verdict: 'bad', verdictPt: 'CONDIÇÕES INSTÁVEIS', verdictEn: 'UNSTABLE CONDITIONS', descPt: 'Descartes de pacotes frequentes durante transições de mapa.', descEn: 'Frequent packet drops during map transitions.' }
      }
    },
    apex: {
      name: 'Apex Legends',
      publisher: 'EA / Respawn',
      image: 'assets/games/apexlegends.jpg',
      regions: {
        'sa-east-1': { location: 'São Paulo (Respawn)', ping: 22, jitter: 1.3, loss: 0.0, verdict: 'ready', verdictPt: 'PRONTO PARA RANKED', verdictEn: 'READY FOR RANKED', descPt: 'Movimentação fluida e cálculos de predição física consistentes.', descEn: 'Fluid movement and consistent physics prediction ticks.' },
        'us-east-1': { location: 'Dallas / Virgínia', ping: 124, jitter: 3.9, loss: 0.2, verdict: 'warn', verdictPt: 'EU EVITARIA RANKED AGORA', verdictEn: 'AVOID RANKED RIGHT NOW', descPt: 'Stutter em transições rápidas de slide e tiro.', descEn: 'Stutter on rapid slide-jumping and weapon swaps.' },
        'eu-central-1': { location: 'Frankfurt (EU)', ping: 189, jitter: 7.5, loss: 0.9, verdict: 'bad', verdictPt: 'CONDIÇÕES INSTÁVEIS', verdictEn: 'UNSTABLE CONDITIONS', descPt: 'Hit-registration inconsistente em alvos em alta velocidade.', descEn: 'Inconsistent hit registration on high-speed targets.' }
      }
    },
    roblox: {
      name: 'Roblox',
      publisher: 'Roblox Corp',
      image: 'assets/games/roblox.jpg',
      regions: {
        'sa-east-1': { location: 'São Paulo Edge', ping: 20, jitter: 1.5, loss: 0.0, verdict: 'ready', verdictPt: 'PRONTO PARA RANKED', verdictEn: 'READY FOR RANKED', descPt: 'Sincronização física perfeita nos nós de borda de São Paulo.', descEn: 'Perfect physics sync across São Paulo edge nodes.' },
        'us-east-1': { location: 'Virgínia Edge', ping: 116, jitter: 3.4, loss: 0.1, verdict: 'warn', verdictPt: 'EU EVITARIA RANKED AGORA', verdictEn: 'AVOID RANKED RIGHT NOW', descPt: 'Atraso moderado em minigames competitivos de precisão.', descEn: 'Moderate latency in competitive precision minigames.' },
        'eu-central-1': { location: 'Frankfurt (EU)', ping: 185, jitter: 6.2, loss: 0.6, verdict: 'bad', verdictPt: 'CONDIÇÕES INSTÁVEIS', verdictEn: 'UNSTABLE CONDITIONS', descPt: 'Atraso de física e risco de descompasso de personagens.', descEn: 'Physics delay and avatar position desync.' }
      }
    }
  };

  let currentSelectedGame = 'valorant';
  let currentSelectedRegion = 'sa-east-1';

  function initSimulator() {
    const chips = document.querySelectorAll('.game-chip-btn');
    const regionSelect = document.getElementById('sim-region-select');
    const runBtn = document.getElementById('btn-run-sim');

    if (!chips.length || !runBtn) return;

    chips.forEach((chip) => {
      chip.addEventListener('click', (e) => {
        e.preventDefault();
        chips.forEach((c) => c.classList.remove('active'));
        chip.classList.add('active');
        currentSelectedGame = chip.getAttribute('data-game') || 'valorant';
        updateSimulatorDisplay(false);
      });
    });

    if (regionSelect) {
      regionSelect.addEventListener('change', () => {
        currentSelectedRegion = regionSelect.value;
        updateSimulatorDisplay(false);
      });
    }

    runBtn.addEventListener('click', (e) => {
      e.preventDefault();
      runSimulationCheck();
    });

    window.addEventListener('nolaggy:langchange', () => {
      updateSimulatorDisplay(false);
    });

    updateSimulatorDisplay(false);
  }

  function runSimulationCheck() {
    const runBtn = document.getElementById('btn-run-sim');
    const nodeBoxes = document.querySelectorAll('.route-node-box');
    const pingEl = document.getElementById('sim-metric-ping');
    const jitterEl = document.getElementById('sim-metric-jitter');
    const lossEl = document.getElementById('sim-metric-loss');
    const isEn = document.body.classList.contains('lang-en');

    if (!runBtn) return;

    runBtn.disabled = true;
    runBtn.innerHTML = `
      <span class="pulse-dot"></span>
      <span>${isEn ? 'AUDITING ROUTE...' : 'AUDITANDO ROTA...'}</span>
    `;

    // Step 1: Animate node 1
    nodeBoxes.forEach((b) => b.classList.remove('active-node'));
    if (nodeBoxes[0]) nodeBoxes[0].classList.add('active-node');

    setTimeout(() => {
      // Step 2: Animate node 2
      if (nodeBoxes[1]) nodeBoxes[1].classList.add('active-node');
    }, 200);

    setTimeout(() => {
      // Step 3: Animate node 3
      if (nodeBoxes[2]) nodeBoxes[2].classList.add('active-node');
    }, 450);

    setTimeout(() => {
      updateSimulatorDisplay(true);
      runBtn.disabled = false;
      runBtn.innerHTML = `
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
        <span>${isEn ? 'RUN READY CHECK' : 'FAZER CHECK DE ROTA'}</span>
      `;
    }, 700);
  }

  function updateSimulatorDisplay(animate) {
    const game = GAME_DATA[currentSelectedGame] || GAME_DATA.valorant;
    const regData = game.regions[currentSelectedRegion] || game.regions['sa-east-1'];
    const isEn = document.body.classList.contains('lang-en');

    // Update Node 3 Datacenter label
    const nodeTarget = document.getElementById('sim-node-target-name');
    const nodeTargetLoc = document.getElementById('sim-node-target-location');
    if (nodeTarget) nodeTarget.textContent = `${game.name} Cluster`;
    if (nodeTargetLoc) nodeTargetLoc.textContent = regData.location;

    // Update Verdict Badge
    const verdictBox = document.getElementById('sim-verdict-box');
    const verdictTitle = document.getElementById('sim-verdict-title');
    const verdictDesc = document.getElementById('sim-verdict-desc');

    if (verdictBox) {
      verdictBox.className = `verdict-large-badge ${regData.verdict}`;
    }
    if (verdictTitle) {
      const icon = regData.verdict === 'ready' ? '● ' : '▲ ';
      verdictTitle.textContent = icon + (isEn ? regData.verdictEn : regData.verdictPt);
    }
    if (verdictDesc) {
      verdictDesc.textContent = isEn ? regData.descEn : regData.descPt;
    }

    // Update Metrics with smooth count-up
    const pingEl = document.getElementById('sim-metric-ping');
    const jitterEl = document.getElementById('sim-metric-jitter');
    const lossEl = document.getElementById('sim-metric-loss');

    if (pingEl) {
      if (animate) {
        animateValue(pingEl, 0, regData.ping, 400, ' ms');
      } else {
        pingEl.textContent = `${regData.ping} ms`;
      }
    }
    if (jitterEl) jitterEl.textContent = `${regData.jitter.toFixed(1)} ms`;
    if (lossEl) lossEl.textContent = `${regData.loss.toFixed(1)}%`;

    // Also update phone cockpit hero preview
    const phoneGameName = document.querySelector('.phone-game-name');
    const phoneGameRegion = document.querySelector('.phone-game-region');
    const phoneGameImg = document.querySelector('.phone-game-card img');
    if (phoneGameName) phoneGameName.textContent = game.name;
    if (phoneGameRegion) phoneGameRegion.textContent = regData.location;
    if (phoneGameImg) phoneGameImg.src = game.image;
  }

  function animateValue(element, start, end, duration, suffix) {
    let startTimestamp = null;
    const step = (timestamp) => {
      if (!startTimestamp) startTimestamp = timestamp;
      const progress = Math.min((timestamp - startTimestamp) / duration, 1);
      const val = Math.floor(progress * (end - start) + start);
      element.textContent = `${val}${suffix}`;
      if (progress < 1) {
        window.requestAnimationFrame(step);
      }
    };
    window.requestAnimationFrame(step);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();

