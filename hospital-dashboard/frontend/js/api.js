// Shared helpers: API calls and formatting.

export async function api(path) {
  const res = await fetch('/api' + path);
  let data = null;
  try { data = await res.json(); } catch { /* not JSON */ }
  if (!res.ok) throw new Error((data && data.error) || `Request failed (${res.status})`);
  return data;
}

export const esc = (s) =>
  String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

export const num = (n) => Number(n || 0).toLocaleString('en-IN');
export const inr = (n) => '₹' + Number(n || 0).toLocaleString('en-IN', { maximumFractionDigits: 0 });

export function fmtDate(s) {
  if (!s) return '—';
  const d = new Date(String(s).slice(0, 10) + 'T00:00:00');
  if (isNaN(d)) return esc(s);
  return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
}

export function fmtTime(s) {
  if (!s) return '';
  const [h, m] = String(s).split(':');
  const hour = Number(h);
  return `${((hour + 11) % 12) + 1}:${m} ${hour >= 12 ? 'PM' : 'AM'}`;
}

export const badge = (v) =>
  v ? `<span class="badge b-${esc(String(v).toLowerCase())}">${esc(v)}</span>` : '—';

export const initials = (name) =>
  String(name || '?').replace(/^Dr\.\s*/, '').split(/\s+/).slice(0, 2).map((w) => w[0]).join('').toUpperCase();

export const errorBox = (e) =>
  `<div class="error-box"><strong>Could not load data.</strong> ${esc(e.message || e)}<br>
   <small>Check that MySQL is running, <code>hospital_db</code> exists and <code>db.properties</code> is correct.</small></div>`;
