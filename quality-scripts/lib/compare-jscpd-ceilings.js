#!/usr/bin/env node
'use strict';
const fs = require('fs');

const reportPath = process.argv[2];
const baselinePath = process.argv[3];
if (!reportPath || !baselinePath) {
  console.error('usage: compare-jscpd-ceilings.js <report.json> <baseline.json>');
  process.exit(2);
}

const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
const baseline = JSON.parse(fs.readFileSync(baselinePath, 'utf8'));
const total = report.statistics?.total || report.total || {};
const clones = Number(total.clones ?? 0);
const percentage = Number(total.percentage ?? 0);
const maxClones = Number(baseline.maxClones);
const maxPct = Number(baseline.maxDuplicatedLinesPercent);
const failures = [];
if (!Number.isFinite(maxClones) || !Number.isFinite(maxPct)) {
  failures.push('baseline missing maxClones / maxDuplicatedLinesPercent');
}
if (clones > maxClones) {
  failures.push('clones ' + clones + ' exceeds maxClones ' + maxClones);
}
if (percentage > maxPct) {
  failures.push(
    'duplicatedLines% ' + percentage.toFixed(4) + ' exceeds maxDuplicatedLinesPercent ' + maxPct,
  );
}
if (failures.length) {
  console.error('jscpd check FAILED.');
  console.error('Never raise scripts/jscpd-baseline.json ceilings without an explicit paydown task.');
  for (const f of failures) console.error('  ' + f);
  process.exit(1);
}
console.log(
  'jscpd check OK (clones=' +
    clones +
    '/' +
    maxClones +
    ', duplicatedLines%=' +
    percentage.toFixed(2) +
    '/' +
    maxPct +
    ')',
);
