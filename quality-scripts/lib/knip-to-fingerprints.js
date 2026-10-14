#!/usr/bin/env node
'use strict';
const fs = require('fs');

const jsonPath = process.argv[2];
const outPath = process.argv[3];
const prefix = process.argv[4] || ''; // optional e.g. "knip:"
if (!jsonPath || !outPath) {
  console.error('usage: knip-to-fingerprints.js <knip.json> <out.txt> [prefix]');
  process.exit(2);
}

const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
const kinds = [
  'files',
  'exports',
  'types',
  'dependencies',
  'devDependencies',
  'duplicates',
  'enumMembers',
  'nsExports',
  'nsTypes',
  'unlisted',
  'unresolved',
  'binaries',
  'catalog',
  'catalogReferences',
  'namespaceMembers',
  'optionalPeerDependencies',
];
const fps = new Set();
for (const issue of data.issues || []) {
  const file = issue.file || '';
  for (const kind of kinds) {
    for (const item of issue[kind] || []) {
      const name = typeof item === 'string' ? item : item.name;
      if (!name) continue;
      fps.add(prefix + kind + ':' + file + ':' + name);
    }
  }
}
fs.writeFileSync(
  outPath,
  [...fps].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0)).join('\n') + (fps.size ? '\n' : ''),
);
