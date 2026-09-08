/* ════════════════════════════════════════════════════════════
   TAREQO — interações do site
   Navbar, menu móvel, troca de idioma, reveal on scroll,
   FAQ (uma pergunta aberta) e formulário de contacto (mailto).
   ════════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var i18n = window.TAREQO_I18N;

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
  var openIcon = document.getElementById('burgerOpen');
  var closeIcon = document.getElementById('burgerClose');
  var menuOpen = false;

  function setMenu(open) {
    if (!burger || !links) return;
    menuOpen = !!open;
    links.classList.toggle('is-open', menuOpen);
    burger.setAttribute('aria-expanded', menuOpen ? 'true' : 'false');
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
  document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape' && menuOpen) {
      setMenu(false);
      burger.focus();
    }
  });
  window.addEventListener('resize', function () {
    if (window.innerWidth > 1040 && menuOpen) setMenu(false);
  });

  /* ── Idioma ────────────────────────────────────────────── */
  if (i18n) {
    var langBtns = document.querySelectorAll('.lang-btn');
    Array.prototype.forEach.call(langBtns, function (btn) {
      btn.addEventListener('click', function () {
        i18n.apply(btn.getAttribute('data-lang'));
      });
    });

    // Ao mudar o idioma, atualiza o aria-label do burger
    // (registrado ANTES do apply inicial para não perder o evento)
    document.addEventListener('tareqo:lang', function () {
      setMenu(menuOpen);
    });

    i18n.apply(i18n.lang);
  }

  /* ── Reveal on scroll ──────────────────────────────────── */
  var reveals = document.querySelectorAll('.reveal');
  var prefersReduced = window.matchMedia
    && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  if (prefersReduced || !('IntersectionObserver' in window)) {
    Array.prototype.forEach.call(reveals, function (el) { el.classList.add('in'); });
  } else {
    var observer = new IntersectionObserver(function (entries) {
      Array.prototype.forEach.call(entries, function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('in');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.15, rootMargin: '0px 0px -32px 0px' });
    Array.prototype.forEach.call(reveals, function (el) { observer.observe(el); });
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
