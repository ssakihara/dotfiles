#!/usr/bin/env node
/**
 * Pattern 1: Minimal dots - colored circles with numbers only
 */

const R = '\x1b[0m';
const DIM = '\x1b[2m';
const BOLD = '\x1b[1m';

function gradient(pct) {
  if (pct < 50) {
    const r = Math.floor(pct * 5.1);
    return `\x1b[38;2;${r};200;80m`;
  }
  const g = Math.floor(200 - (pct - 50) * 4);
  return `\x1b[38;2;255;${Math.max(g, 0)};60m`;
}

function dot(pct) {
  const p = Math.round(pct);
  return `${gradient(pct)}●${R} ${BOLD}${p}%${R}`;
}

const RESET_FORMATTER = new Intl.DateTimeFormat('en-GB', {
  timeZone: 'Asia/Tokyo',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  hour12: false,
});

/**
 * Unix epoch秒のリセット時刻を JST の `MM/DD HH:MM` 形式で返す
 * @param {unknown} resetsAt Unix epoch秒
 * @returns {string|null} フォーマット済み文字列。不正値の場合は null
 */
function formatResetTime(resetsAt) {
  if (typeof resetsAt !== 'number' || !Number.isFinite(resetsAt)) return null;
  const parts = RESET_FORMATTER.formatToParts(new Date(resetsAt * 1000));
  const get = (type) => parts.find((p) => p.type === type)?.value ?? '';
  return `${get('month')}/${get('day')} ${get('hour')}:${get('minute')}`;
}

let input = '';
process.stdin.setEncoding('utf-8');
process.stdin.on('data', (chunk) => { input += chunk; });
process.stdin.on('end', () => {
  const data = JSON.parse(input);

  const model = data.model?.display_name ?? 'Claude';
  const parts = [`${BOLD}${model}${R}`];

  const ctx = data.context_window?.used_percentage;
  if (ctx != null) parts.push(`ctx ${dot(ctx)}`);

  const five = data.rate_limits?.five_hour?.used_percentage;
  if (five != null) {
    const resetAt = formatResetTime(data.rate_limits?.five_hour?.resets_at);
    const suffix = resetAt ? ` ${DIM}(reset ${resetAt})${R}` : '';
    parts.push(`5h ${dot(five)}${suffix}`);
  }

  const week = data.rate_limits?.seven_day?.used_percentage;
  if (week != null) parts.push(`7d ${dot(week)}`);

  process.stdout.write(parts.join(`  ${DIM}·${R}  `));
});
