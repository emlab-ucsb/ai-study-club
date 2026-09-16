<script id="mapdata" type="application/json">__MAPS__</script>
<script>
(function(){
"use strict";
var NS="http://www.w3.org/2000/svg";
var MAPS=JSON.parse(document.getElementById("mapdata").textContent);

/* ---------- tiny svg helpers ---------- */
var COLORKEYS={fill:1,stroke:1};
function S(tag,attrs,parent){
  var e=document.createElementNS(NS,tag);
  if(attrs) for(var k in attrs){
    var v=attrs[k];
    if(v===null||v===undefined) continue;
    if(COLORKEYS[k]) e.style[k]=v; else e.setAttribute(k,String(v));
  }
  if(parent) parent.appendChild(e);
  return e;
}
function T(parent,x,y,str,cls,attrs){
  var t=S("text",Object.assign({x:x,y:y,class:cls||"tick"},attrs||{}),parent);
  t.appendChild(document.createTextNode(str));
  return t;
}
function H(tag,cls,text){var e=document.createElement(tag);if(cls)e.className=cls;if(text!=null)e.textContent=text;return e;}

/* ---------- tooltip ---------- */
var tip=document.getElementById("tip");
function showTip(ev,html){
  tip.innerHTML="";
  tip.appendChild(html);
  tip.style.opacity="1";
  moveTip(ev);
}
function moveTip(ev){
  var r=tip.getBoundingClientRect();
  var x=ev.clientX+16, y=ev.clientY+16;
  if(x+r.width>window.innerWidth-10) x=ev.clientX-r.width-16;
  if(y+r.height>window.innerHeight-10) y=ev.clientY-r.height-16;
  tip.style.left=Math.max(8,x)+"px"; tip.style.top=Math.max(8,y)+"px";
}
function hideTip(){tip.style.opacity="0";}
function tipBody(head,rows,extra){
  var f=document.createDocumentFragment();
  if(head){var h=H("div","th",head);f.appendChild(h);}
  (rows||[]).forEach(function(r){
    var d=H("div","tr");
    if(r.color){var k=H("span","tk");k.style.background=r.color;k.style.display="inline-block";d.appendChild(k);}
    var v=H("span","tv",r.value); d.appendChild(v);
    if(r.name){var n=H("span","tn",r.name); d.appendChild(n);}
    f.appendChild(d);
  });
  if(extra){var x=H("div","tx",extra);f.appendChild(x);}
  return f;
}
function bindTip(node,head,rows,extra,mark){
  var lift=mark||node;
  function enter(ev){ lift.style.opacity="0.72"; showTip(ev,tipBody(head,rows,extra)); }
  node.addEventListener("pointerenter",enter);
  node.addEventListener("pointermove",moveTip);
  node.addEventListener("pointerleave",function(){lift.style.opacity="";hideTip();});
  node.setAttribute("tabindex","0");
  node.addEventListener("focus",function(){
    lift.style.opacity="0.72";
    var b=node.getBoundingClientRect();
    showTip({clientX:b.left+b.width/2,clientY:b.top+b.height/2},tipBody(head,rows,extra));
  });
  node.addEventListener("blur",function(){lift.style.opacity="";hideTip();});
}

/* ---------- table builder ---------- */
function buildTable(mount,cols,rows){
  var host=document.getElementById(mount); if(!host) return;
  host.innerHTML="";
  var t=document.createElement("table");
  var thead=document.createElement("thead"), tr=document.createElement("tr");
  cols.forEach(function(c){var th=document.createElement("th");th.textContent=c.label;
    if(c.num)th.style.textAlign="right",th.style.paddingRight="22px";tr.appendChild(th);});
  thead.appendChild(tr); t.appendChild(thead);
  var tb=document.createElement("tbody");
  rows.forEach(function(r){
    var x=document.createElement("tr");
    cols.forEach(function(c){
      var td=document.createElement("td");
      if(c.num) td.className="n";
      if(c.swatch && r[c.swatch]){
        var m=H("span","mk"); m.style.background=r[c.swatch]; td.appendChild(m);
      }
      td.appendChild(document.createTextNode(r[c.key]==null?"—":String(r[c.key])));
      x.appendChild(td);
    });
    tb.appendChild(x);
  });
  t.appendChild(tb); host.appendChild(t);
}
function legend(mount,items){
  var host=document.getElementById(mount); if(!host) return;
  host.innerHTML="";
  items.forEach(function(it){
    var s=H("span","item");
    var sw=H("span",it.shape||"sw"); sw.style.background=it.color;
    if(it.shape==="swdot") sw.style.boxShadow="0 0 0 2px var(--surface-1)";
    s.appendChild(sw); s.appendChild(document.createTextNode(it.label));
    host.appendChild(s);
  });
}
var C={ get s1(){return cssv("--series-1")}, get s2(){return cssv("--series-2")},
        get s3(){return cssv("--series-3")}, get dry(){return cssv("--dry")},
        get wet(){return cssv("--wet")}, get muted(){return cssv("--muted")} };
function cssv(n){return getComputedStyle(document.documentElement).getPropertyValue(n).trim();}

/* ---------- theme ---------- */
var btn=document.getElementById("themeBtn");
function setTheme(dark){
  document.documentElement.setAttribute("data-theme",dark?"dark":"light");
  btn.setAttribute("aria-pressed",dark?"true":"false");
  btn.textContent=dark?"◑ Light mode":"◐ Dark mode";
  renderAll();
}
btn.addEventListener("click",function(){setTheme(document.documentElement.getAttribute("data-theme")!=="dark");});


/* ---------- map projection ---------- */
function proj(m,lon,lat){
  var x=lon-m.lon0;
  while(x<-180)x+=360; while(x>=180)x-=360;
  x+=m.lon0;
  return [(x-m.lonMin)*m.k,(m.latMax-lat)*m.k];
}
/* Catmull-Rom -> cubic bezier through points */
function smooth(pts,tension){
  tension=tension||0.5;
  if(pts.length<2) return "";
  var d="M"+pts[0][0].toFixed(1)+","+pts[0][1].toFixed(1);
  for(var i=0;i<pts.length-1;i++){
    var p0=pts[i-1]||pts[i], p1=pts[i], p2=pts[i+1], p3=pts[i+2]||pts[i+1];
    var c1=[p1[0]+(p2[0]-p0[0])/6*tension*2, p1[1]+(p2[1]-p0[1])/6*tension*2];
    var c2=[p2[0]-(p3[0]-p1[0])/6*tension*2, p2[1]-(p3[1]-p1[1])/6*tension*2];
    d+=" C"+c1[0].toFixed(1)+","+c1[1].toFixed(1)+" "+c2[0].toFixed(1)+","+c2[1].toFixed(1)
      +" "+p2[0].toFixed(1)+","+p2[1].toFixed(1);
  }
  return d;
}
