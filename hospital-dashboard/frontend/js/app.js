// App shell: sidebar, hash routing, global search, notifications.
import { api, esc, errorBox } from './api.js';
import { icon, initIcons } from './icons.js';
import { renderDashboard } from './dashboard.js';
import { renderTables } from './views.js';

const VIEWS = {
  dashboard: { label: 'Dashboard', icon: 'home' },
  patients: {
    label: 'Patients', icon: 'user', subtitle: 'All registered patients',
    tables: [{ name: 'patients', title: 'Patients', filterLabel: 'Gender', placeholder: 'Search by name, ID, phone or blood group…' }],
  },
  doctors: {
    label: 'Doctors & Departments', icon: 'users', subtitle: 'Doctors and the departments they work in',
    tables: [
      { name: 'doctors', title: 'Doctors', filterLabel: 'Department', placeholder: 'Search doctors, specialization or department…' },
      { name: 'departments', title: 'Departments', placeholder: 'Search departments…' },
    ],
  },
  appointments: {
    label: 'Appointments', icon: 'calendar', subtitle: 'Every appointment with its status',
    tables: [{ name: 'appointments', title: 'Appointments', filterLabel: 'Status', placeholder: 'Search patient, doctor, department or reason…' }],
  },
  records: {
    label: 'Medical Records', icon: 'file', subtitle: 'Diagnoses and treatments',
    tables: [{ name: 'records', title: 'Medical Records', placeholder: 'Search patient, doctor or diagnosis…' }],
  },
  prescriptions: {
    label: 'Prescriptions', icon: 'clipboard', subtitle: 'Medicines prescribed to patients',
    tables: [{ name: 'prescriptions', title: 'Prescriptions', filterLabel: 'Category', placeholder: 'Search patient, doctor or medicine…' }],
  },
  pharmacy: {
    label: 'Pharmacy & Inventory', icon: 'package', subtitle: 'Medicine stock levels (low = below 250)',
    tables: [{ name: 'pharmacy', title: 'Medicines', filterLabel: 'Category', placeholder: 'Search medicine, category or manufacturer…' }],
  },
  rooms: {
    label: 'Rooms & Admissions', icon: 'bed', subtitle: 'Room availability and admission history',
    tables: [
      { name: 'rooms', title: 'Rooms', filterLabel: 'Room type', placeholder: 'Search room number, type or department…' },
      { name: 'admissions', title: 'Admissions', filterLabel: 'Status', placeholder: 'Search patient or room…' },
    ],
  },
  billing: {
    label: 'Billing & Revenue', icon: 'rupee', subtitle: 'Bills and payment status',
    tables: [{ name: 'billing', title: 'Bills', filterLabel: 'Payment status', placeholder: 'Search by bill ID or patient…' }],
  },
};

const $ = (s) => document.querySelector(s);
const content = $('#content');

/* ---------- toast ---------- */
let toastTimer;
function toast(msg) {
  const t = $('#toast');
  t.textContent = msg;
  t.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => (t.hidden = true), 2600);
}

/* ---------- routing (#/patients?filter=Unpaid) ---------- */
function parseHash() {
  const [path, qs] = location.hash.replace(/^#\/?/, '').split('?');
  return { view: VIEWS[path] ? path : 'dashboard', params: Object.fromEntries(new URLSearchParams(qs || '')) };
}

export function navigate(view, params = {}) {
  const qs = new URLSearchParams(Object.entries(params).filter(([, v]) => v)).toString();
  const target = `#/${view}${qs ? '?' + qs : ''}`;
  if (location.hash === target) render();
  else location.hash = target;
}

function render() {
  const { view, params } = parseHash();
  document.querySelectorAll('#nav .nav-link').forEach((a) => a.classList.toggle('active', a.dataset.nav === view));
  closeSidebar();
  window.scrollTo(0, 0);
  if (view === 'dashboard') renderDashboard(content);
  else renderTables(content, VIEWS[view], params);
  loadNotifications();
}

/* ---------- sidebar ---------- */
function buildNav() {
  $('#nav').innerHTML = Object.entries(VIEWS).map(([key, v]) =>
    `<a href="#/${key}" class="nav-link" data-nav="${key}">${icon(v.icon, 22)}<span>${esc(v.label)}</span></a>`).join('');
}
const closeSidebar = () => { $('#sidebar').classList.remove('open'); $('#scrim').classList.remove('show'); };
$('#burger').addEventListener('click', () => { $('#sidebar').classList.toggle('open'); $('#scrim').classList.toggle('show'); });
$('#scrim').addEventListener('click', closeSidebar);

// Any element with data-nav (cards, "View All", quick actions) navigates; sidebar links use the hash directly.
document.addEventListener('click', (e) => {
  const stub = e.target.closest('[data-stub]');
  if (stub) { e.preventDefault(); toast(`${stub.dataset.stub} is not part of this project (no login or settings tables).`); return; }
  const el = e.target.closest('[data-nav]');
  if (el && !el.matches('#nav .nav-link')) {
    e.preventDefault();
    navigate(el.dataset.nav, { filter: el.dataset.filter });
  }
});
window.addEventListener('hashchange', render);

/* ---------- global search ---------- */
const searchInput = $('#search-input');
const results = $('#search-results');
let searchTimer;

searchInput.addEventListener('input', () => {
  clearTimeout(searchTimer);
  const q = searchInput.value.trim();
  if (q.length < 2) { results.hidden = true; return; }
  searchTimer = setTimeout(async () => {
    try {
      const r = await api('/search?q=' + encodeURIComponent(q));
      const groups = [
        ['Patients', r.patients, 'patients'],
        ['Doctors', r.doctors, 'doctors'],
        ['Medicines', r.medicines, 'pharmacy'],
      ].filter(([, rows]) => rows.length);
      results.innerHTML = groups.length
        ? groups.map(([title, rows, view]) => `
            <div class="dd-group"><div class="dd-title">${title}</div>
              ${rows.map((x) => `<button class="dd-item" data-view="${view}" data-q="${esc(x.name.replace(/^Dr\. /, ''))}">
                <strong>${esc(x.name)}</strong><small>${esc(x.detail || '')}</small></button>`).join('')}
            </div>`).join('')
        : '<div class="dd-empty">No matches found</div>';
      results.hidden = false;
    } catch (e) {
      results.innerHTML = errorBox(e);
      results.hidden = false;
    }
  }, 250);
});

results.addEventListener('click', (e) => {
  const item = e.target.closest('.dd-item');
  if (!item) return;
  results.hidden = true;
  searchInput.value = '';
  navigate(item.dataset.view, { q: item.dataset.q });
});

/* ---------- notifications ---------- */
async function loadNotifications() {
  const badgeEl = $('#notif-count');
  try {
    const notes = await api('/notifications');
    badgeEl.textContent = notes.length;
    badgeEl.hidden = notes.length === 0;
    $('#notif-panel').innerHTML = notes.length
      ? `<div class="dd-group">${notes.map((n) => `
          <button class="dd-item" data-view="${n.view}" data-filter="${n.filter || ''}">
            <strong><span class="note-level lv-${n.level}"></span>${esc(n.title)}</strong><small>${esc(n.detail)}</small>
          </button>`).join('')}</div>`
      : '<div class="dd-empty">You are all caught up</div>';
  } catch {
    badgeEl.hidden = true;
    $('#notif-panel').innerHTML = '<div class="dd-empty">Notifications unavailable</div>';
  }
}

$('#notif-btn').addEventListener('click', (e) => { e.stopPropagation(); $('#notif-panel').hidden = !$('#notif-panel').hidden; });
$('#notif-panel').addEventListener('click', (e) => {
  const item = e.target.closest('.dd-item');
  if (!item) return;
  $('#notif-panel').hidden = true;
  navigate(item.dataset.view, { filter: item.dataset.filter });
});
document.addEventListener('click', (e) => {
  if (!e.target.closest('#search')) results.hidden = true;
  if (!e.target.closest('#notif')) $('#notif-panel').hidden = true;
});

/* ---------- start ---------- */
initIcons();
buildNav();
render();
