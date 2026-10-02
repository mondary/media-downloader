(() => {
  const meta = {
    fr: ['PKMediaDownloader — gardez ce qui compte.', 'Un lien, un fichier sur votre Mac, puis l’extrait qui compte. Découvrez PKMediaDownloader, téléchargeable en DMG ou avec Homebrew.'],
    en: ['PKMediaDownloader — keep what matters.', 'A link, a file on your Mac, then the clip worth keeping. Explore PKMediaDownloader, available as a DMG or through Homebrew.']
  };
  const stateNames = {fr: ['01 / LIEN', '02 / FICHIER', '03 / EXTRAIT'], en: ['01 / LINK', '02 / FILE', '03 / CLIP']};
  let current = 0;
  const stages = [...document.querySelectorAll('.stage')];
  const chapters = [...document.querySelectorAll('.chapter')];
  const previous = document.getElementById('previous');
  const next = document.getElementById('next');
  const status = document.getElementById('copy-status');

  function setStage(index) {
    current = Math.max(0, Math.min(stages.length - 1, index));
    stages.forEach((stage, i) => {
      stage.classList.toggle('is-active', i === current);
      stage.setAttribute('aria-hidden', String(i !== current));
      stage.inert = i !== current;
    });
    chapters.forEach((chapter, i) => chapter.classList.toggle('is-current', i === current));
    document.getElementById('workspace-state').textContent = stateNames[document.documentElement.lang][current];
    document.getElementById('step-count').textContent = `0${current + 1} / 03`;
    document.getElementById('progress-fill').style.width = `${(current + 1) / stages.length * 100}%`;
    previous.disabled = current === 0;
    next.disabled = current === stages.length - 1;
  }
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
    setStage(current);
    if (status.dataset.state) status.textContent = lang === 'en' ? (status.dataset.state === 'copied' ? 'Command copied.' : 'Select the command above to copy it.') : (status.dataset.state === 'copied' ? 'Commande copiée.' : 'Sélectionnez la commande ci-dessus pour la copier.');
    if (remember) { try { localStorage.setItem('pkmd-language', lang); } catch (_) {} }
    updateTrim();
  }
  document.querySelectorAll('[data-language]').forEach(el => el.addEventListener('click', () => language(el.dataset.language, true)));
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  function goTo(index) {
    setStage(index);
    if (innerWidth > 760) chapters[current].scrollIntoView({behavior: reduced.matches ? 'instant' : 'smooth', block: 'center'});
    else document.getElementById('workspace-stage').scrollIntoView({behavior: reduced.matches ? 'instant' : 'smooth', block: 'center'});
  }
  previous.addEventListener('click', () => goTo(current - 1));
  next.addEventListener('click', () => goTo(current + 1));
  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver(entries => {
      if (innerWidth <= 760) return;
      const visible = entries.filter(entry => entry.isIntersecting).sort((a, b) => b.intersectionRatio - a.intersectionRatio);
      if (visible.length) setStage(Number(visible[0].target.dataset.index));
    }, {rootMargin: '-28% 0px -28% 0px', threshold: [0, .25, .5, .75]});
    chapters.forEach(chapter => observer.observe(chapter));
  }
  const trim = document.getElementById('trim-range');
  function updateTrim() {
    const end = Number(trim.value);
    document.getElementById('selection').style.width = `${(end - 4) / 18 * 100}%`;
    document.getElementById('trim-clock').textContent = `00:04 — 00:${String(end).padStart(2, '0')}`;
    trim.setAttribute('aria-valuetext', document.documentElement.lang === 'en' ? `${end} seconds` : `${end} secondes`);
  }
  trim.addEventListener('input', updateTrim);
  document.getElementById('copy-brew').addEventListener('click', async () => {
    const code = document.getElementById('brew-command');
    let copied = false;
    try { await navigator.clipboard.writeText(code.textContent); copied = true; } catch (_) {}
    if (!copied) {
      const range = document.createRange(); range.selectNodeContents(code);
      const selection = window.getSelection(); selection.removeAllRanges(); selection.addRange(range);
      try { copied = document.execCommand('copy'); } catch (_) {}
      selection.removeAllRanges();
    }
    status.dataset.state = copied ? 'copied' : 'failed';
    status.textContent = document.documentElement.lang === 'en' ? (copied ? 'Command copied.' : 'Select the command above to copy it.') : (copied ? 'Commande copiée.' : 'Sélectionnez la commande ci-dessus pour la copier.');
  });
  language(document.documentElement.lang === 'en' ? 'en' : 'fr');
})();
