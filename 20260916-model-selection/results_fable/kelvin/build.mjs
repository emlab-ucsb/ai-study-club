import fs from 'fs';
let h=fs.readFileSync('template.html','utf8');
h=h.replace('__LAND__',fs.readFileSync('data/pacific.json','utf8')).replace('__NINO__',fs.readFileSync('data/nino34_events.json','utf8')).replace('__GAUGES__',fs.readFileSync('data/gauges.json','utf8'));
fs.writeFileSync('kelvin-wave-2026.html',h); console.log('wrote', fs.statSync('kelvin-wave-2026.html').size,'bytes');
