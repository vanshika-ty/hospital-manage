// Sidebar pages (Patients, Doctors, ...): searchable, filterable tables backed by /api/list/{name}.
import { api, esc, inr, fmtDate, fmtTime, badge, errorBox } from './api.js';
import { icon } from './icons.js';

const STATUS_KEY = /^(status|payment_status|availability|stock_status)$/;
const DATE_KEY = /(_date|_on)$|^date_of_birth$/;
const TIME_KEY = /_time$/;
const MONEY_KEY = /^(salary|unit_price|price_per_day|total_amount)$|_(charges|fees|cost)$/;

const pretty = (k) => k.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());

function cell(key, v) {
  if (v === null || v === undefined || v === '') return '<td class="muted-text">—</td>';
  if (STATUS_KEY.test(key)) return `<td>${badge(v)}</td>`;
  if (MONEY_KEY.test(key)) return `<td class="num">${inr(v)}</td>`;
  if (DATE_KEY.test(key)) return `<td style="white-space:nowrap">${fmtDate(v)}</td>`;
  if (TIME_KEY.test(key)) return `<td style="white-space:nowrap">${fmtTime(v)}</td>`;
  return `<td>${esc(v)}</td>`;
}

function tableHtml(rows) {
  if (!rows.length) return '<div class="empty">No records found.</div>';
  const keys = Object.keys(rows[0]);
  const head = keys.map((k) => `<th class="${MONEY_KEY.test(k) ? 'num' : ''}">${pretty(k)}</th>`).join('');
  const body = rows.map((r) => `<tr>${keys.map((k) => cell(k, r[k])).join('')}</tr>`).join('');
  return `<table><thead><tr>${head}</tr></thead><tbody>${body}</tbody></table>`;
}

export function renderTables(el, view, params = {}) {
  el.innerHTML = `
    <div class="page-head"><div><h1>${esc(view.label)}</h1><p>${esc(view.subtitle || '')}</p></div></div>
    <div id="tables"></div>`;
  const host = el.querySelector('#tables');
  view.tables.forEach((t, i) => mountTable(host, t, i === 0 ? params : {}));
}

async function mountTable(host, t, params) {
  const card = document.createElement('section');
  card.className = 'card table-card';
  card.innerHTML = `
    <div class="card-head"><h3>${esc(t.title)}</h3><span class="count"></span></div>
    <div class="toolbar">
      <div class="field">${icon('search', 16)}<input type="search" placeholder="${esc(t.placeholder || 'Search…')}" value="${esc(params.q || '')}"></div>
      ${t.filterLabel ? `<select aria-label="${esc(t.filterLabel)}"><option value="">All ${esc(t.filterLabel.toLowerCase())}s</option></select>` : ''}
    </div>
    <div class="table-wrap"><div class="skeleton" style="height:140px"></div></div>`;
  host.append(card);

  const input = card.querySelector('input');
  const select = card.querySelector('select');
  const out = card.querySelector('.table-wrap');
  const count = card.querySelector('.count');

  async function refresh() {
    const qs = new URLSearchParams();
    if (input.value.trim()) qs.set('q', input.value.trim());
    if (select && select.value) qs.set('filter', select.value);
    try {
      const rows = await api(`/list/${t.name}?${qs}`);
      out.innerHTML = tableHtml(rows);
      count.textContent = `${rows.length} record${rows.length === 1 ? '' : 's'}`;
    } catch (e) {
      out.innerHTML = errorBox(e);
    }
  }

  if (select) {
    try {
      const values = await api(`/list/${t.name}/filters`);
      select.insertAdjacentHTML('beforeend', values.map((v) => `<option value="${esc(v)}">${esc(v)}</option>`).join(''));
      if (t.name === 'billing') {
        select.insertAdjacentHTML('beforeend', '<option value="Unpaid">Unpaid (Pending + Partial)</option>');
      }
      if (params.filter) {
        if (![...select.options].some((o) => o.value === params.filter)) {
          select.insertAdjacentHTML('beforeend', `<option value="${esc(params.filter)}">${esc(params.filter)}</option>`);
        }
        select.value = params.filter;
      }
    } catch { /* the table request below will show the error */ }
    select.addEventListener('change', refresh);
  }

  let timer;
  input.addEventListener('input', () => { clearTimeout(timer); timer = setTimeout(refresh, 250); });
  refresh();
}
