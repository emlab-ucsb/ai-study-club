import fs from 'fs';
// ---- TopoJSON -> simplified GeoJSON, Pacific-centered (lon' = lon-180 wrapped) ----
const topo = JSON.parse(fs.readFileSync('data/countries-110m.json','utf8'));
const {scale, translate} = topo.transform;
const arcs = topo.arcs.map(arc => { let x=0,y=0; return arc.map(([dx,dy]) => { x+=dx; y+=dy; return [x*scale[0]+translate[0], y*scale[1]+translate[1]]; }); });
function ring(arcIdxs){ let pts=[]; for(const i of arcIdxs){ let a = i<0 ? arcs[~i].slice().reverse() : arcs[i]; if(pts.length) a=a.slice(1); pts=pts.concat(a);} return pts; }
const shift = lon => { let l = lon-180; if(l< -180) l+=360; if (l>=180) l-=360; return l; };
const out=[];
for (const g of topo.objects.countries.geometries){
  const polys = g.type==='Polygon' ? [g.arcs] : g.arcs;
  for (const poly of polys){
    const outer = ring(poly[0]).map(([lo,la])=>[shift(lo),la]);
    // drop rings that straddle the new cut (Greenwich meridian in original coords)
    let bad=false; for(let i=1;i<outer.length;i++){ if(Math.abs(outer[i][0]-outer[i-1][0])>180) bad=true; }
    // straddlers (cross Greenwich) -> move negative lon' to +360 side; renderer draws them twice (±360)
    const pts = outer.map(([x,y])=>[+((bad && x<0) ? x+360 : x).toFixed(1), +y.toFixed(1)]);
    out.push(bad ? {s:1, p:pts} : pts);
  }
}
fs.writeFileSync('data/pacific.json', JSON.stringify(out));
console.log('rings', out.length, 'bytes', fs.statSync('data/pacific.json').size);

// ---- Weekly Nino 3.4 anomalies for 1997, 2015, 2026 ----
const wk = fs.readFileSync('data/wksst.txt','utf8').split('\n').filter(l=>/^\s*\d{2}[A-Z]{3}\d{4}/.test(l));
const mon={JAN:0,FEB:1,MAR:2,APR:3,MAY:4,JUN:5,JUL:6,AUG:7,SEP:8,OCT:9,NOV:10,DEC:11};
const nino={};
for (const l of wk){
  const d=l.trim().slice(0,9); const day=+d.slice(0,2), m=mon[d.slice(2,5)], y=+d.slice(5,9);
  const nums = l.slice(9).match(/-?\d+\.\d/g).map(Number); // 8 numbers: 1+2 sst, ssta, 3 sst, ssta, 34 sst, ssta, 4 sst, ssta
  const doy = Math.round((Date.UTC(y,m,day)-Date.UTC(y,0,1))/864e5);
  (nino[y] ||= []).push({doy, n12:nums[1], n3:nums[3], n34:nums[5], n4:nums[7]});
}
const events = {};
for (const y of [1997,2015,2023,2026]){
  const series=[]; for (const {doy,n34,n12} of nino[y]) series.push([doy, n34, n12]);
  if (nino[y+1]) for (const {doy,n34,n12} of nino[y+1]) series.push([doy+365, n34, n12]);
  events[y]=series.filter(p=>p[0]<=365+181);
}
fs.writeFileSync('data/nino34_events.json', JSON.stringify(events));
console.log('2026 weeks', events[2026].length, 'last', events[2026].at(-1));

// ---- Tide gauge monthly MSL anomalies (inches) vs 1996-2025 monthly climatology ----
function gauge(file){
  const d = JSON.parse(fs.readFileSync(file,'utf8')).data.map(r=>({y:+r.year,m:+r.month,msl:+r.MSL})).filter(r=>!isNaN(r.msl));
  const clim=Array.from({length:12},()=>[]);
  for(const r of d) if(r.y>=1996 && r.y<=2025) clim[r.m-1].push(r.msl);
  const cm = clim.map(a=>a.reduce((s,v)=>s+v,0)/a.length);
  const anom = d.map(r=>({y:r.y,m:r.m,a:+((r.msl-cm[r.m-1])*12).toFixed(1)}));
  const ev={};
  for (const y of [1997,2015,2023,2026]) ev[y]=anom.filter(r=>(r.y===y)||(r.y===y+1&&r.m<=6)).map(r=>[(r.y-y)*12+r.m-1, r.a]);
  return {events:ev, last: anom.at(-1)};
}
const sf=gauge('data/sf_msl.json'), lj=gauge('data/lj_msl.json');
fs.writeFileSync('data/gauges.json', JSON.stringify({sf:sf.events, lj:lj.events}));
console.log('SF last', sf.last, 'LJ last', lj.last);
console.log('SF 2026', JSON.stringify(sf.events[2026]));
console.log('SF 2015 peak', Math.max(...sf.events[2015].map(p=>p[1])), 'SF 1997 peak', Math.max(...sf.events[1997].map(p=>p[1])));
console.log('LJ 2026', JSON.stringify(lj.events[2026]));
