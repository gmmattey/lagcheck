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
    initAlgorithmDemo();
    bindAnalyticsTracking();
  }

  // --- Analytics & Demand Intent Tracking ---
  function trackEvent(eventName, eventData = {}) {
    try {
      const storageKey = "lagcheck_web_events";
      const events = JSON.parse(localStorage.getItem(storageKey) || "[]");
      const eventPayload = {
        event: eventName,
        data: eventData,
        timestamp: new Date().toISOString(),
        lang: document.body.classList.contains("lang-en") ? "en" : "pt"
      };
      events.push(eventPayload);
      if (events.length > 50) events.shift();
      localStorage.setItem(storageKey, JSON.stringify(events));
      window.dispatchEvent(new CustomEvent("lagcheck:telemetry", { detail: eventPayload }));
    } catch (err) {}
  }

  function bindAnalyticsTracking() {
    document.querySelectorAll("[data-event]").forEach((el) => {
      el.addEventListener("click", () => {
        const eventName = el.getAttribute("data-event");
        const eventVal = el.getAttribute("data-event-val") || "";
        trackEvent(eventName, { target: eventVal });
      });
    });
  }

  // --- Demonstrador do Algoritmo de Diagnóstico ---
  const SCENARIOS = {
    stable: {
      badgeClass: "ready",
      verdictPt: "● PRONTO PARA RANKED",
      verdictEn: "● READY FOR RANKED",
      descPt: "Latência baixa e estável em repouso e sob carga. Respostas UDP consistentes sem bufferbloat.",
      descEn: "Low, stable latency at rest and under stress. Consistent UDP probe responses with zero bufferbloat.",
      ping: "18 ms",
      jitter: "1.1 ms",
      loss: "0.0%",
      node1SubPt: "Wi-Fi 5 GHz • NAT Aberto (Tipo 2)",
      node1SubEn: "Wi-Fi 5 GHz • Open NAT (Type 2)",
      node2SubPt: "Backbone Fibra • 0% Perda",
      node2SubEn: "Fiber Backbone • 0% Loss",
      reasoningPt: "<strong>Diagnóstico Técnico:</strong> Durante as rajadas de estresse controladas, a variação de latência (jitter) permaneceu abaixo de 2 ms e não houve descarte de pacotes. A fila do roteador escoa sem atraso. Condição segura para entrar em filas ranqueadas.",
      reasoningEn: "<strong>Technical Assessment:</strong> Controlled packet bursts produced less than 2 ms latency variation with zero packet drops. Router queue flushes cleanly. Favorable and safe conditions for ranked matchmaking."
    },
    bufferbloat: {
      badgeClass: "warn",
      verdictPt: "▲ EU EVITARIA RANKED AGORA",
      verdictEn: "▲ AVOID RANKED RIGHT NOW",
      descPt: "Bufferbloat severo detectado. A rota em repouso parece boa (24 ms), mas quadruplica sob carga (142 ms).",
      descEn: "Severe bufferbloat detected. Idle ping looks acceptable (24 ms), but spikes fourfold under load (142 ms).",
      ping: "142 ms",
      jitter: "18.4 ms",
      loss: "1.2%",
      node1SubPt: "Wi-Fi 2.4 GHz • Fila Local Saturada",
      node1SubEn: "Wi-Fi 2.4 GHz • Local Queue Saturated",
      node2SubPt: "Bufferbloat no Roteador / CPE",
      node2SubEn: "Router Bufferbloat / CPE Saturation",
      reasoningPt: "<strong>Diagnóstico Técnico:</strong> A medição em repouso deu falsa impressão de estabilidade. Quando o teste injetou tráfego concorrente simulando o jogo, a latência explodiu para 142 ms. Em partida real, qualquer download de fundo causará tiros fantasmas e travamentos.",
      reasoningEn: "<strong>Technical Assessment:</strong> Idle measurement gave a false impression of stability. Under synthetic load bursts, latency spiked to 142 ms. In a real match, any concurrent streaming or background traffic will trigger hit-reg desync and rubberbanding."
    },
    inconclusive: {
      badgeClass: "neutral",
      verdictPt: "— INCONCLUSIVO (SEM NOTA INVENTADA)",
      verdictEn: "— INCONCLUSIVE (NO SCORE)",
      descPt: "Menos de 10 respostas UDP válidas recebidas ou descarte severo de rota. Nenhuma nota foi fabricada.",
      descEn: "Fewer than 10 valid UDP responses received or critical route drops. No score is fabricated.",
      ping: "— ms",
      jitter: "— ms",
      loss: "64.0%",
      node1SubPt: "Troca de Interface / Rota Quebrada",
      node1SubEn: "Interface Switch / Broken Route",
      node2SubPt: "Respostas UDP Insuficientes",
      node2SubEn: "Insufficient UDP Responses",
      reasoningPt: "<strong>Princípio de Integridade:</strong> O Lagcheck se recusa a chutar notas ou inventar aproximações por ping HTTP quando a rota não fornece dados UDP matematicamente conclusivos. O teste é descartado para proteger a integridade do jogador.",
      reasoningEn: "<strong>Scientific Integrity:</strong> Lagcheck refuses to guess scores or substitute HTTP approximations when network probes yield mathematically insufficient UDP samples. The test is safely discarded to protect the player."
    }
  };

  const GAME_TARGETS = {
    valorant: { name: "Valorant", image: "assets/games/valorant.jpg", clusterSa: "São Paulo (BR1)", clusterNa: "Virgínia (NA-East)", clusterEu: "Frankfurt (EU)" },
    cs2: { name: "Counter-Strike 2", image: "assets/games/cs2.jpg", clusterSa: "São Paulo (GRU)", clusterNa: "Virgínia (US)", clusterEu: "Frankfurt (EU)" },
    lol: { name: "League of Legends", image: "assets/games/leagueoflegends.jpg", clusterSa: "São Paulo (BR1)", clusterNa: "Chicago / Virgínia", clusterEu: "Frankfurt (EUW)" },
    fortnite: { name: "Fortnite", image: "assets/games/fortnite.jpg", clusterSa: "São Paulo (sa-east-1)", clusterNa: "Virgínia (us-east-1)", clusterEu: "Frankfurt (eu-central-1)" },
    eafc: { name: "EA Sports FC 25", image: "assets/games/eafc.jpg", clusterSa: "São Paulo (EA Hub)", clusterNa: "Miami / Virgínia", clusterEu: "Frankfurt (EU)" },
    warzone: { name: "CoD Warzone", image: "assets/games/warzone.jpg", clusterSa: "São Paulo (Battle.net BR)", clusterNa: "Dallas / Virgínia", clusterEu: "Frankfurt (EU)" },
    apex: { name: "Apex Legends", image: "assets/games/apexlegends.jpg", clusterSa: "São Paulo (Respawn)", clusterNa: "Dallas / Virgínia", clusterEu: "Frankfurt (EU)" },
    roblox: { name: "Roblox", image: "assets/games/roblox.jpg", clusterSa: "São Paulo Edge", clusterNa: "Virgínia Edge", clusterEu: "Frankfurt (EU)" }
  };

  let currentScenarioKey = "stable";
  let currentTargetGame = "valorant";
  let currentRegionKey = "sa-east-1";

  function initAlgorithmDemo() {
    const scenarioBtns = document.querySelectorAll(".scenario-btn");
    const chips = document.querySelectorAll(".game-chip-btn");
    const regionSelect = document.getElementById("sim-region-select");

    if (!scenarioBtns.length) return;

    scenarioBtns.forEach((btn) => {
      btn.addEventListener("click", (e) => {
        e.preventDefault();
        scenarioBtns.forEach((b) => b.classList.remove("active"));
        btn.classList.add("active");
        currentScenarioKey = btn.getAttribute("data-scenario") || "stable";
        trackEvent("scenario_selected", { scenario: currentScenarioKey });
        updateDemoDisplay();
      });
    });

    chips.forEach((chip) => {
      chip.addEventListener("click", (e) => {
        e.preventDefault();
        chips.forEach((c) => c.classList.remove("active"));
        chip.classList.add("active");
        currentTargetGame = chip.getAttribute("data-game") || "valorant";
        trackEvent("game_selected", { game: currentTargetGame });
        updateDemoDisplay();
      });
    });

    if (regionSelect) {
      regionSelect.addEventListener("change", () => {
        currentRegionKey = regionSelect.value;
        trackEvent("region_selected", { region: currentRegionKey });
        updateDemoDisplay();
      });
    }

    window.addEventListener("nolaggy:langchange", () => {
      updateDemoDisplay();
    });

    updateDemoDisplay();
  }

  function updateDemoDisplay() {
    const scenario = SCENARIOS[currentScenarioKey] || SCENARIOS.stable;
    const game = GAME_TARGETS[currentTargetGame] || GAME_TARGETS.valorant;
    const isEn = document.body.classList.contains("lang-en");

    // Update Node 1 & Node 2 subtitles
    const node1Sub = document.getElementById("sim-node-1-sub");
    const node2Sub = document.getElementById("sim-node-2-sub");
    if (node1Sub) node1Sub.textContent = isEn ? scenario.node1SubEn : scenario.node1SubPt;
    if (node2Sub) node2Sub.textContent = isEn ? scenario.node2SubEn : scenario.node2SubPt;

    // Update Node 3 Datacenter target
    const nodeTarget = document.getElementById("sim-node-target-name");
    const nodeTargetLoc = document.getElementById("sim-node-target-location");
    if (nodeTarget) nodeTarget.textContent = game.name + " Cluster";
    if (nodeTargetLoc) {
      let loc = game.clusterSa;
      if (currentRegionKey === "us-east-1") loc = game.clusterNa;
      if (currentRegionKey === "eu-central-1") loc = game.clusterEu;
      nodeTargetLoc.textContent = loc;
    }

    // Update Verdict Badge
    const verdictBox = document.getElementById("sim-verdict-box");
    const verdictTitle = document.getElementById("sim-verdict-title");
    const verdictDesc = document.getElementById("sim-verdict-desc");

    if (verdictBox) {
      verdictBox.className = "verdict-large-badge " + scenario.badgeClass;
    }
    if (verdictTitle) {
      verdictTitle.textContent = isEn ? scenario.verdictEn : scenario.verdictPt;
    }
    if (verdictDesc) {
      verdictDesc.textContent = isEn ? scenario.descEn : scenario.descPt;
    }

    // Update Metrics
    const pingEl = document.getElementById("sim-metric-ping");
    const jitterEl = document.getElementById("sim-metric-jitter");
    const lossEl = document.getElementById("sim-metric-loss");
    if (pingEl) pingEl.textContent = scenario.ping;
    if (jitterEl) jitterEl.textContent = scenario.jitter;
    if (lossEl) lossEl.textContent = scenario.loss;

    // Update Reasoning Card
    const reasoningBox = document.getElementById("algorithm-reasoning-content");
    if (reasoningBox) {
      reasoningBox.innerHTML = isEn ? scenario.reasoningEn : scenario.reasoningPt;
    }

    // Sync phone cockpit preview
    const phoneGameName = document.querySelector(".phone-game-name");
    const phoneGameRegion = document.querySelector(".phone-game-region");
    const phoneGameImg = document.querySelector(".phone-game-card img");
    if (phoneGameName) phoneGameName.textContent = game.name;
    if (phoneGameRegion) phoneGameRegion.textContent = nodeTargetLoc ? nodeTargetLoc.textContent : game.clusterSa;
    if (phoneGameImg) phoneGameImg.src = game.image;
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();

