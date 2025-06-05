document.addEventListener('DOMContentLoaded', () => {
  const toggle = document.getElementById('theme-toggle');
  const root = document.documentElement;

  function applyTheme(theme) {
    if (theme === 'dark') {
      root.setAttribute('data-theme', 'dark');
    } else {
      root.removeAttribute('data-theme');
    }
  }

  let stored = null;
  try {
    stored = localStorage.getItem('theme');
  } catch (e) {
    // ignore if storage access is blocked
  }
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  const initial = stored || (prefersDark ? 'dark' : 'light');
  applyTheme(initial);

  if (toggle) {
    toggle.addEventListener('click', () => {
      const isDark = root.getAttribute('data-theme') === 'dark';
      const newTheme = isDark ? 'light' : 'dark';
      applyTheme(newTheme);
      try {
        localStorage.setItem('theme', newTheme);
      } catch (e) {
        // ignore if storage access is blocked
      }
    });
  }
});

