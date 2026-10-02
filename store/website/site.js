(() => {
  const meta = {
    fr: ['PKMediaDownloader — télécharge, garde, découpe.', 'Une app macOS native qui transforme un lien en fichier sur votre Mac : téléchargement yt-dlp, historique et découpe d’extrait. DMG ou Homebrew.'],
    en: ['PKMediaDownloader — download, keep, trim.', 'A native macOS app that turns a link into a file on your Mac: yt-dlp download, history and clip trimming. DMG or Homebrew.']
  };
  const status = document.getElementById('copy-status');

  function language(lang, remember = false) {
    document.querySelectorAll('[data-fr]').forEach(el => { el.textContent = el.dataset[lang]; });
    document.querySelectorAll('[data-fr-alt]').forEach(el => { el.alt = el.dataset[`${lang}Alt`]; });
    document.querySelectorAll('[data-fr-aria-label]').forEach(el => { el.setAttribute('aria-label', el.dataset[`${lang}AriaLabel`]); });
    document.querySelectorAll('[data-language]').forEach(el => el.setAttribute('aria-pressed', String(el.dataset.language === lang)));
    document.title = meta[lang][0];
    document.querySelector('meta[name="description"]').content = meta[lang][1];
    document.querySelector('meta[property="og:title"]').content = meta[lang][0];
    document.querySelector('meta[property="og:description"]').content = meta[lang][1];
    document.documentElement.lang = lang;
    document.documentElement.classList.remove('i18n-pending');
    if (status?.dataset.state) {
      status.textContent = lang === 'en'
        ? (status.dataset.state === 'copied' ? 'Command copied.' : 'Select the command above to copy it.')
        : (status.dataset.state === 'copied' ? 'Commande copiée.' : 'Sélectionnez la commande ci-dessus pour la copier.');
    }
    if (remember) { try { localStorage.setItem('pkmd-language', lang); } catch (_) {} }
  }
  document.querySelectorAll('[data-language]').forEach(el => el.addEventListener('click', () => language(el.dataset.language, true)));

  const tabs = [...document.querySelectorAll('.demo-tabs [role="tab"]')];
  function selectTab(tab) {
    tabs.forEach(item => {
      const active = item === tab;
      item.setAttribute('aria-selected', String(active));
      item.tabIndex = active ? 0 : -1;
    });
    document.getElementById('panel-capture').setAttribute('aria-labelledby', tab.id);
    document.querySelectorAll('.capture').forEach(image => {
      image.classList.toggle('is-active', image.classList.contains(`capture-${tab.dataset.panel}`));
    });
  }
  tabs.forEach((tab, index) => {
    tab.addEventListener('click', () => selectTab(tab));
    tab.addEventListener('keydown', event => {
      if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') return;
      event.preventDefault();
      const next = tabs[(index + (event.key === 'ArrowRight' ? 1 : tabs.length - 1)) % tabs.length];
      next.focus();
      selectTab(next);
    });
  });

  document.getElementById('copy-brew').addEventListener('click', async () => {
    const code = document.getElementById('brew-command');
    let copied = false;
    try { await navigator.clipboard.writeText(code.textContent); copied = true; } catch (_) {}
    if (!copied) {
      const range = document.createRange();
      range.selectNodeContents(code);
      const selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
      try { copied = document.execCommand('copy'); } catch (_) {}
      selection.removeAllRanges();
    }
    status.dataset.state = copied ? 'copied' : 'failed';
    status.textContent = document.documentElement.lang === 'en'
      ? (copied ? 'Command copied.' : 'Select the command above to copy it.')
      : (copied ? 'Commande copiée.' : 'Sélectionnez la commande ci-dessus pour la copier.');
  });

  language(document.documentElement.lang === 'en' ? 'en' : 'fr');
})();
