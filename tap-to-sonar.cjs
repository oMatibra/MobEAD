'use strict';

// Converte o relatorio TAP do node:test para o formato generico do SonarQube.
// Uso: node tap-to-sonar.cjs tests.tap sonar-tests.xml
// Para testar por pipe: node tap-to-sonar.cjs - -

const fs = require('node:fs');

const [input, output] = process.argv.slice(2);
if (!input || !output) {
    console.error('Uso: node tap-to-sonar.cjs ARQUIVO_TAP ARQUIVO_XML');
    process.exit(2);
}

const tap = input === '-' ? fs.readFileSync(0, 'utf8') : fs.readFileSync(input, 'utf8');
const escapeXml = (s) => String(s).replace(/&/g, '&amp;').replace(/"/g, '&quot;')
    .replace(/</g, '&lt;').replace(/>/g, '&gt;');

const cases = [];
let current = null;
for (const line of tap.split(/\r?\n/)) {
    const match = /^ok \d+ - (.+)$/.exec(line);
    if (match) {
        current = { name: match[1], duration: 0 };
        cases.push(current);
        continue;
    }
    const duration = /^\s+duration_ms:\s*([\d.]+)/.exec(line);
    if (duration && current) current.duration = Math.round(Number(duration[1]));
}

if (!cases.length || /^(?:not ok) \d+ - /m.test(tap) || !/^# fail 0$/m.test(tap)) {
    console.error('Relatorio TAP incompleto ou testes com falha; XML nao gerado.');
    process.exit(1);
}

const xml = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<testExecutions version="1">',
    '  <file path="mobead.test.cjs">',
    ...cases.map((item) => `    <testCase name="${escapeXml(item.name)}" duration="${item.duration}"/>`),
    '  </file>',
    '</testExecutions>',
    ''
].join('\n');

if (output === '-') process.stdout.write(xml);
else fs.writeFileSync(output, xml);
