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
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
