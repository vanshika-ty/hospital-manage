// Dashboard front page. Every number, table row and chart point is fetched from the Java API (MySQL).
import { api, esc, num, inr, fmtDate, fmtTime, badge, initials, errorBox } from './api.js';
import { icon } from './icons.js';

const PALETTE = ['#14b8a6', '#3b82f6', '#f97316', '#facc15', '#a855f7', '#22c55e', '#ef4444', '#64748b'];
const STATUS_COLORS = { Completed: '#22c55e', Scheduled: '#3b82f6', Cancelled: '#ef4444' };

let charts = [];

const card = (id, title, navView, extraHead = '') => `
  <section class="card" id="${id}">
    <div class="card-head">
      <h3>${title}</h3>
      <div class="card-tools">${extraHead}
        ${navView ? `<button class="link" data-nav="${navView}">View All →</button>` : ''}
      </div>
    </div>
    <div class="body"><div class="skeleton" style="height:160px"></div></div>
  </section>`;

function template() {
  const today = new Date().toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
  return `
    <div class="page-head">
      <div><h1>Dashboard</h1><p>Welcome to Hospital Management System</p></div>
      <div class="today">${icon('calendar', 24)}<div><small>Today</small><strong>${today}</strong></div></div>
    </div>

    <section class="cards" id="cards">
      ${'<div class="stat"><div class="ic teal skeleton"></div><div><div class="lbl skeleton">Loading</div><div class="val skeleton">00</div></div></div>'.repeat(5)}
    </section>

    <div class="quick">
      <span>Quick actions</span>
      <button class="pill" data-nav="patients">${icon('user', 16)} View Patients</button>
      <button class="pill" data-nav="appointments">${icon('calendar', 16)} View Appointments</button>
      <button class="pill" data-nav="doctors">${icon('stethoscope', 16)} View Doctors</button>
      <button class="pill" data-nav="billing" data-filter="Unpaid">${icon('rupee', 16)} View Pending Bills</button>
    </div>

    <div class="grid-3">
      ${card('c-monthly', 'Monthly Appointments', null)}
      ${card('c-revenue', 'Department-wise Revenue', null)}
      ${card('c-status', 'Appointment Status', null)}
    </div>

    <div class="grid-2">
      ${card('c-appts', 'Recent Appointments', 'appointments', `
        <select class="sel-sm" id="appt-status" aria-label="Filter by status">
          <option value="">All statuses</option><option>Scheduled</option><option>Completed</option><option>Cancelled</option>
        </select>`)}
      ${card('c-patients', 'Recently Registered Patients', 'patients')}
    </div>

    <div class="grid-3">
      ${card('c-rooms', 'Room Availability', 'rooms')}
      ${card('c-pharmacy', 'Low Stock Medicines', 'pharmacy')}
      ${card('c-billing', 'Billing Summary', 'billing')}
    </div>`;
}

/** Runs a loader; shows an error message inside the card if it fails. */
async function load(id, fn) {
  const body = document.querySelector(`#${id} .body`);
  try {
    await fn(body);
  } catch (e) {
    body.innerHTML = errorBox(e);
  }
}

export async function renderDashboard(el) {
  charts.forEach((c) => c.destroy());
  charts = [];
  el.innerHTML = template();

  document.getElementById('appt-status').addEventListener('change', () => loadAppointments());

  await Promise.allSettled([
    loadSummary(),
    load('c-monthly', monthlyChart),
    load('c-revenue', revenueChart),
    load('c-status', statusChart),
    loadAppointments(),
    load('c-patients', patientsTable),
    load('c-rooms', roomsWidget),
    load('c-pharmacy', pharmacyWidget),
    load('c-billing', billingWidget),
  ]);
}

/* ---------------- summary cards ---------------- */
async function loadSummary() {
  const host = document.getElementById('cards');
  try {
    const s = await api('/summary');
    const occupied = s.total_rooms - s.available_rooms;
    const items = [
      { c: 'teal', i: 'users', l: 'Total Patients', v: num(s.total_patients), s: 'Registered patients', nav: 'patients' },
      { c: 'blue', i: 'stethoscope', l: 'Total Doctors', v: num(s.total_doctors), s: `Across ${s.total_departments} departments`, nav: 'doctors' },
      { c: 'red', i: 'calendar', l: 'Total Appointments', v: num(s.total_appointments), s: `${s.scheduled_appointments} scheduled`, nav: 'appointments' },
      { c: 'green', i: 'bed', l: 'Available Rooms', v: `${s.available_rooms} / ${s.total_rooms}`, s: `${occupied} occupied`, nav: 'rooms' },
      { c: 'amber', i: 'rupee', l: 'Pending Payments', v: inr(s.pending_amount), s: `${s.pending_payments} pending bills`, nav: 'billing', f: 'Unpaid' },
    ];
    host.innerHTML = items.map((x) => `
      <div class="stat" data-nav="${x.nav}" ${x.f ? `data-filter="${x.f}"` : ''}>
        <div class="ic ${x.c}">${icon(x.i, 26)}</div>
        <div><div class="lbl">${x.l}</div><div class="val">${x.v}</div><div class="sub">${esc(x.s)}</div></div>
      </div>`).join('');
  } catch (e) {
    host.innerHTML = `<div style="grid-column:1/-1">${errorBox(e)}</div>`;
  }
}

/* ---------------- charts ---------------- */
function chartsReady(body) {
  if (window.Chart) return true;
  body.innerHTML = '<div class="empty">Chart library could not be loaded (internet access is needed once for Chart.js).</div>';
  return false;
}

const legendHtml = (labels, values, colors) => {
  const total = values.reduce((a, b) => a + b, 0) || 1;
  return `<div class="legend">${labels.map((l, i) =>
    `<div><i style="background:${colors[i]}"></i><span>${esc(l)}</span><b>${Math.round((values[i] / total) * 100)}%</b></div>`).join('')}</div>`;
};

async function monthlyChart(body) {
  const rows = await api('/charts/monthly-appointments');
  if (!rows.length) { body.innerHTML = '<div class="empty">No appointments yet.</div>'; return; }
  if (!chartsReady(body)) return;
  body.innerHTML = '<div class="chart-box"><canvas></canvas></div>';

  const valueLabels = {
    id: 'valueLabels',
    afterDatasetsDraw(chart) {
      const { ctx } = chart;
      ctx.save();
      ctx.font = '600 12px Inter, Segoe UI, sans-serif';
      ctx.fillStyle = '#12263a';
      ctx.textAlign = 'center';
      chart.getDatasetMeta(0).data.forEach((bar, i) => ctx.fillText(chart.data.datasets[0].data[i], bar.x, bar.y - 6));
      ctx.restore();
    },
  };
  charts.push(new Chart(body.querySelector('canvas'), {
    type: 'bar',
    data: { labels: rows.map((r) => r.label), datasets: [{ data: rows.map((r) => r.total), backgroundColor: '#6cb8f5', borderRadius: 6, maxBarThickness: 44 }] },
    options: {
      maintainAspectRatio: false,
      plugins: { legend: { display: false }, tooltip: { callbacks: { label: (c) => ` ${c.parsed.y} appointments` } } },
      scales: {
        y: { beginAtZero: true, ticks: { precision: 0 }, grid: { color: '#eef3f7' }, border: { display: false } },
        x: { grid: { display: false } },
      },
    },
    plugins: [valueLabels],
  }));
}

function donut(body, labels, values, colors, centerTop, centerBottom, cutout) {
  body.innerHTML = `<div class="chart-split"><div class="chart-box"><canvas></canvas></div>${legendHtml(labels, values, colors)}</div>`;
  const center = {
    id: 'center',
    afterDraw(chart) {
      if (!centerTop) return;
      const { ctx, chartArea: a } = chart;
      const x = (a.left + a.right) / 2, y = (a.top + a.bottom) / 2;
      ctx.save();
      ctx.textAlign = 'center';
      ctx.fillStyle = '#12263a';
      ctx.font = '700 17px Inter, Segoe UI, sans-serif';
      ctx.fillText(centerTop, x, y + 2);
      ctx.fillStyle = '#64748b';
      ctx.font = '12px Inter, Segoe UI, sans-serif';
      ctx.fillText(centerBottom, x, y + 20);
      ctx.restore();
    },
  };
  charts.push(new Chart(body.querySelector('canvas'), {
    type: 'doughnut',
    data: { labels, datasets: [{ data: values, backgroundColor: colors, borderColor: '#fff', borderWidth: 2 }] },
    options: { maintainAspectRatio: false, cutout, plugins: { legend: { display: false } } },
    plugins: [center],
  }));
}

async function revenueChart(body) {
  const rows = await api('/charts/department-revenue');
  if (!rows.length) { body.innerHTML = '<div class="empty">No billing data yet.</div>'; return; }
  if (!chartsReady(body)) return;
  const values = rows.map((r) => Number(r.revenue));
  const total = values.reduce((a, b) => a + b, 0);
  donut(body, rows.map((r) => r.dept_name), values, rows.map((_, i) => PALETTE[i % PALETTE.length]),
    inr(total), 'Total Revenue', '62%');
}

async function statusChart(body) {
  const rows = await api('/charts/appointment-status');
  if (!rows.length) { body.innerHTML = '<div class="empty">No appointments yet.</div>'; return; }
  if (!chartsReady(body)) return;
  donut(body, rows.map((r) => r.status), rows.map((r) => r.total),
    rows.map((r, i) => STATUS_COLORS[r.status] || PALETTE[i]), '', '', '0%');
}

/* ---------------- tables ---------------- */
async function loadAppointments() {
  await load('c-appts', async (body) => {
    const status = document.getElementById('appt-status').value;
    const rows = await api('/appointments/recent?limit=6' + (status ? '&status=' + encodeURIComponent(status) : ''));
    body.innerHTML = rows.length ? `
      <div class="table-wrap"><table>
        <thead><tr><th>ID</th><th>Patient</th><th>Doctor</th><th>Department</th><th>Date &amp; Time</th><th>Status</th></tr></thead>
        <tbody>${rows.map((r) => `
          <tr>
            <td>${r.appointment_id}</td>
            <td><div class="who-cell"><span class="mini-av">${initials(r.patient_name)}</span>${esc(r.patient_name)}</div></td>
            <td>${esc(r.doctor_name)}</td>
            <td>${esc(r.department)}</td>
            <td style="white-space:nowrap">${fmtDate(r.appointment_date)} <span class="muted-text">${fmtTime(r.appointment_time)}</span></td>
            <td>${badge(r.status)}</td>
          </tr>`).join('')}</tbody>
      </table></div>` : '<div class="empty">No appointments found.</div>';
  });
}

async function patientsTable(body) {
  const rows = await api('/patients/recent?limit=6');
  body.innerHTML = rows.length ? `
    <div class="table-wrap"><table>
      <thead><tr><th>ID</th><th>Name</th><th>Gender</th><th>Blood</th><th>Registered</th></tr></thead>
      <tbody>${rows.map((r) => `
        <tr>
          <td>${r.patient_id}</td>
          <td><div class="who-cell"><span class="mini-av">${initials(r.name)}</span>${esc(r.name)}</div></td>
          <td>${esc(r.gender)}</td>
          <td>${esc(r.blood_group)}</td>
          <td style="white-space:nowrap">${fmtDate(r.registered_on)}</td>
        </tr>`).join('')}</tbody>
    </table></div>` : '<div class="empty">No patients yet.</div>';
}

/* ---------------- bottom widgets ---------------- */
async function roomsWidget(body) {
  const { summary: s } = await api('/rooms/availability');
  const tile = (cls, ic, label, val, sub = '') =>
    `<div class="tile"><div class="ic sm ${cls}">${icon(ic, 22)}</div><div><div class="lbl">${label}</div><div class="val">${val}</div>${sub ? `<div class="sub">${sub}</div>` : ''}</div></div>`;
  body.innerHTML = `<div class="tiles">
    ${tile('blue', 'bed', 'Total Rooms', s.total_rooms)}
    ${tile('green', 'bed', 'Available', s.available_rooms)}
    ${tile('red', 'bed', 'Occupied', s.occupied_rooms)}
    ${tile('purple', 'bed', 'ICU Available', `${s.icu_available} / ${s.icu_total}`)}
  </div>`;
}

async function pharmacyWidget(body) {
  const { threshold, items } = await api('/pharmacy/low-stock?limit=6');
  if (!items.length) { body.innerHTML = '<div class="all-good">All medicines are well stocked.</div>'; return; }
  body.innerHTML = `
    <div class="table-wrap"><table>
      <thead><tr><th>Medicine</th><th class="num">Stock</th><th class="num">Price</th></tr></thead>
      <tbody>${items.map((m) => `
        <tr>
          <td>${esc(m.med_name)}<div class="muted-text" style="font-size:12px">${esc(m.category)}</div></td>
          <td class="num"><span class="chip ${m.stock_qty < threshold * 0.5 ? 'red' : 'amber'}">${num(m.stock_qty)}</span></td>
          <td class="num">${inr(m.unit_price)}</td>
        </tr>`).join('')}</tbody>
    </table></div>
    <p class="muted-text" style="font-size:12px;margin-top:8px">Showing medicines with stock below ${threshold}.</p>`;
}

async function billingWidget(body) {
  const b = await api('/billing/summary');
  const tile = (cls, ic, label, val, sub) =>
    `<div class="tile"><div class="ic sm ${cls}">${icon(ic, 22)}</div><div><div class="lbl">${label}</div><div class="val">${inr(val)}</div><div class="sub">${sub}</div></div></div>`;
  body.innerHTML = `<div class="tiles">
    ${tile('green', 'rupee', 'Total Revenue', b.total_revenue, `${b.total_bills} bills`)}
    ${tile('blue', 'check', 'Paid Bills', b.paid_amount, `${b.paid_count} bills`)}
    ${tile('amber', 'clock', 'Pending Payments', b.pending_amount, `${b.pending_count} bills`)}
    ${tile('purple', 'clock', 'Partial Payments', b.partial_amount, `${b.partial_count} bills`)}
  </div>`;
}
