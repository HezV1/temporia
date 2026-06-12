(async () => {
  const statusEl = document.getElementById('lab-status');
  const lastActiveEl = document.getElementById('last-active');
  const alertCountEl = document.getElementById('alert-count');
  const labelEl = statusEl.querySelector('.status-label');

  function setStatus(state, label) {
    statusEl.className = `status-badge status-${state}`;
    labelEl.textContent = label;
  }

  try {
    const res = await fetch('./status.json', { cache: 'no-store' });
    if (!res.ok) throw new Error('not found');

    const data = await res.json();

    if (data.cluster_online) {
      setStatus('online', 'FORGE ONLINE');
    } else {
      setStatus('offline', 'LAB OFFLINE');
    }

    if (data.last_active) {
      const d = new Date(data.last_active);
      lastActiveEl.textContent = d.toLocaleDateString('en-US', {
        year: 'numeric', month: 'short', day: 'numeric',
        hour: '2-digit', minute: '2-digit', timeZoneName: 'short'
      });
    }

    if (typeof data.recent_alerts === 'number') {
      alertCountEl.textContent = data.recent_alerts;
    }
  } catch {
    setStatus('offline', 'LAB OFFLINE');
    lastActiveEl.textContent = 'Cluster torn down';
    alertCountEl.textContent = '—';
  }
})();
