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
  if (five != null) parts.push(`5h ${dot(five)}`);

  const week = data.rate_limits?.seven_day?.used_percentage;
  if (week != null) parts.push(`7d ${dot(week)}`);

  process.stdout.write(parts.join(`  ${DIM}·${R}  `));
});
