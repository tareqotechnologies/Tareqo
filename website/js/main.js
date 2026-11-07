/* ════════════════════════════════════════════════════════════
   TAREQO — interações do site
   Navbar, menu móvel, idioma, reveal on scroll, secção ativa,
   FAQ (uma pergunta aberta) e formulário de contacto (mailto).
   ════════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var i18n = window.TAREQO_I18N;
  var reduceMotion = window.matchMedia
    && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ── Navbar: estado "scrolled" ─────────────────────────── */
  var nav = document.querySelector('.nav');
  function syncNav() {
    if (nav) nav.classList.toggle('is-scrolled', window.scrollY > 8);
  }
  syncNav();
  window.addEventListener('scroll', syncNav, { passive: true });

  /* ── Menu móvel ────────────────────────────────────────── */
  var burger = document.getElementById('navBurger');
  var links = document.getElementById('navLinks');
  var backdrop = document.getElementById('navBackdrop');
  var openIcon = document.getElementById('burgerOpen');
  var closeIcon = document.getElementById('burgerClose');
  var menuOpen = false;

  function setMenu(open) {
    if (!burger || !links) return;
    menuOpen = !!open;
    links.classList.toggle('is-open', menuOpen);
    burger.setAttribute('aria-expanded', menuOpen ? 'true' : 'false');
    document.body.classList.toggle('nav-open', menuOpen);
    if (backdrop) backdrop.hidden = !menuOpen;

    var label = i18n && i18n.t(menuOpen ? 'nav.menuClose' : 'nav.menuOpen');
    if (label) burger.setAttribute('aria-label', label);
    if (openIcon && closeIcon) {
      openIcon.classList.toggle('is-hidden', menuOpen);
      closeIcon.classList.toggle('is-hidden', !menuOpen);
    }
  }

  if (burger) {
    burger.addEventListener('click', function () { setMenu(!menuOpen); });
  }
  if (links) {
    links.addEventListener('click', function (event) {
      if (event.target.closest('a')) setMenu(false);
    });
  }
  if (backdrop) {
    backdrop.addEventListener('click', function () { setMenu(false); });
  }
  document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape' && menuOpen) {
      setMenu(false);
      burger.focus();
    }
  });
  window.addEventListener('resize', function () {
    if (window.innerWidth > 1024 && menuOpen) setMenu(false);
  });

  /* ── Idioma ────────────────────────────────────────────── */
  function syncLangButtons() {
    var buttons = document.querySelectorAll('.lang-btn');
    var current = i18n ? i18n.lang : 'pt';
    Array.prototype.forEach.call(buttons, function (btn) {
      var active = btn.getAttribute('data-lang') === current;
      btn.classList.toggle('is-active', active);
      btn.setAttribute('aria-pressed', active ? 'true' : 'false');
    });
  }

  if (i18n) {
    var langButtons = document.querySelectorAll('.lang-btn');
    Array.prototype.forEach.call(langButtons, function (btn) {
      btn.addEventListener('click', function () {
        i18n.apply(btn.getAttribute('data-lang'));
      });
    });

    // Ao mudar o idioma, atualiza o aria-label do burger
    document.addEventListener('tareqo:lang', function () {
      syncLangButtons();
      setMenu(menuOpen);
    });

    i18n.apply(i18n.lang);
    syncLangButtons();
  }

  /* ── Reveal on scroll ──────────────────────────────────── */
  var reveals = document.querySelectorAll('.reveal');

  // Pequeno escalonamento para irmãos que entram juntos
  Array.prototype.forEach.call(reveals, function (el) {
    var siblings = el.parentElement
      ? el.parentElement.querySelectorAll(':scope > .reveal')
      : [];
    if (siblings.length > 1) {
      var index = Array.prototype.indexOf.call(siblings, el);
      el.style.setProperty('--reveal-delay', Math.min(index * 60, 300) + 'ms');
    }
  });

  if (reduceMotion || !('IntersectionObserver' in window)) {
    Array.prototype.forEach.call(reveals, function (el) { el.classList.add('in'); });
  } else {
    var observer = new IntersectionObserver(function (entries) {
      Array.prototype.forEach.call(entries, function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('in');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
    Array.prototype.forEach.call(reveals, function (el) { observer.observe(el); });
  }

  /* ── Ligação ativa na navegação ────────────────────────── */
  var sectionLinks = Array.prototype.slice.call(
    document.querySelectorAll('.nav-links a[href^="#"]')
  );
  var sections = sectionLinks.map(function (link) {
    return document.querySelector(link.getAttribute('href'));
  }).filter(Boolean);

  if (sections.length) {
    var ticking = false;

    function syncActiveLink() {
      ticking = false;
      var line = window.scrollY + (nav ? nav.offsetHeight : 76) + 120;
      var active = null;
      sections.forEach(function (section) {
        if (section.offsetTop <= line && section.offsetTop + section.offsetHeight > line) {
          active = section;
        }
      });
      sectionLinks.forEach(function (link) {
        var isActive = active && link.getAttribute('href') === '#' + active.id;
        link.classList.toggle('is-active', !!isActive);
        if (isActive) link.setAttribute('aria-current', 'true');
        else link.removeAttribute('aria-current');
      });
    }

    function requestSync() {
      if (ticking) return;
      ticking = true;
      window.requestAnimationFrame(syncActiveLink);
    }

    syncActiveLink();
    window.addEventListener('scroll', requestSync, { passive: true });
    window.addEventListener('resize', requestSync);
  }

  /* ── Tabela de planos: indicador de deslocamento ───────── */
  var tableShell = document.querySelector('.table-shell');
  var tableFrame = document.querySelector('.table-frame');
  if (tableShell && tableFrame) {
    var syncTableFade = function () {
      var max = tableShell.scrollWidth - tableShell.clientWidth;
      tableFrame.classList.toggle('is-scrollable', max > 8);
      tableFrame.classList.toggle('is-end', tableShell.scrollLeft >= max - 8);
    };
    syncTableFade();
    tableShell.addEventListener('scroll', syncTableFade, { passive: true });
    window.addEventListener('resize', syncTableFade);
  }

  /* ── FAQ: apenas uma pergunta aberta de cada vez ───────── */
  var faqs = document.querySelectorAll('details.faq');
  Array.prototype.forEach.call(faqs, function (item) {
    item.addEventListener('toggle', function () {
      if (!item.open) return;
      Array.prototype.forEach.call(faqs, function (other) {
        if (other !== item) other.open = false;
      });
    });
  });

  /* ── Formulário de contacto → mailto ───────────────────── */
  var form = document.getElementById('contactForm');
  if (form) {
    form.addEventListener('submit', function (event) {
      event.preventDefault();
      var value = function (name) {
        var field = form.elements[name];
        return field ? String(field.value || '').trim() : '';
      };

      var name = value('name');
      var business = value('business');
      var email = value('email');
      var message = value('message');

      var subject = '[TAREQO] ' + ((i18n && i18n.t('ct.subject')) || 'Contacto do site');
      if (business) subject += ' — ' + business;

      var identity = [name, email ? '<' + email + '>' : ''].filter(Boolean).join(' ');
      var header = [identity, business].filter(Boolean).join(' · ');
      var body = header + '\n\n' + message;

      window.location.href = 'mailto:contacto@tareqo.app'
        + '?subject=' + encodeURIComponent(subject)
        + '&body=' + encodeURIComponent(body);
    });
  }
})();
