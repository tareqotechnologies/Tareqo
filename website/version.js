(() => {
  const versionLabels = document.querySelectorAll('[data-version-label]');
  const buildLabels = document.querySelectorAll('[data-build-label]');
  if (!versionLabels.length) return;

  fetch('https://api.github.com/repos/tareqotechnologies/Tareqo/releases/latest', {
    headers: { Accept: 'application/vnd.github+json' },
    cache: 'no-store',
  })
    .then((response) => {
      if (!response.ok) throw new Error('Release metadata unavailable');
      return response.json();
    })
    .then((release) => {
      const tag = release.tag_name;
      if (typeof tag !== 'string' || !/^v?\d+\.\d+\.\d+(?:\+\d+)?$/.test(tag)) return;

      const version = tag.startsWith('v') ? tag : `v${tag}`;
      const build = tag.match(/\+(\d+)$/)?.[1];
      versionLabels.forEach((label) => { label.textContent = version; });
      if (build) {
        buildLabels.forEach((label) => { label.textContent = `Build ${build}`; });
      } else {
        buildLabels.forEach((label) => { label.hidden = true; });
      }
    })
    .catch(() => {
      // Keep the version bundled with this site if GitHub is unavailable.
    });
})();
