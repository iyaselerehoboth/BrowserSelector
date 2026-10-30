(() => {
  const root = document.documentElement;
  const system = window.matchMedia('(prefers-color-scheme: dark)');
  let preference;
  try {
    const stored = localStorage.getItem('browserselector-theme');
    if (stored === 'light' || stored === 'dark') preference = stored;
  } catch { /* Theme selection still works when storage is unavailable. */ }

  function applyTheme() {
    const dark = (preference || (system.matches ? 'dark' : 'light')) === 'dark';
    root.dataset.theme = dark ? 'dark' : 'light';
    const meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.content = dark ? '#121826' : '#f5f7fb';
    const toggle = document.querySelector('.theme-toggle');
    if (toggle) {
      toggle.hidden = false;
      toggle.setAttribute('aria-checked', String(dark));
      toggle.title = `Switch to ${dark ? 'light' : 'dark'} mode`;
    }
  }

  applyTheme();
  system.addEventListener('change', () => { if (!preference) applyTheme(); });
  document.addEventListener('DOMContentLoaded', () => {
    applyTheme();
    document.querySelector('.theme-toggle').addEventListener('click', () => {
      preference = root.dataset.theme === 'dark' ? 'light' : 'dark';
      try { localStorage.setItem('browserselector-theme', preference); } catch { /* Optional persistence. */ }
      applyTheme();
    });
  });
})();
