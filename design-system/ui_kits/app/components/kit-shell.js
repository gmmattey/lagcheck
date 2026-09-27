window.LagCheckKit = {
  mountLiveChip(target, text) {
    if (!target) return;
    target.innerHTML = `<span class="lc-live-chip" aria-label="Telemetria local disponível"><i aria-hidden="true"></i>${text}</span>`;
  }
};
