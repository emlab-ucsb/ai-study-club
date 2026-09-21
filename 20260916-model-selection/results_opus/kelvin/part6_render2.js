
/* ===================== STACKED BAR ===================== */
function renderStack(){
  var svg=document.getElementById("stackChart"); svg.innerHTML="";
  var W=1000,Hh=300,L=250,R=90,Tp=54,B=44;
  svg.setAttribute("viewBox","0 0 "+W+" "+Hh);
  var pw=W-L-R, ph=Hh-Tp-B, xmax=26;
  var X=function(v){return L+pw*v/xmax;};
  var bh=24, rowH=ph/STACK.rows.length;

  /* gridlines every 4 in + doubling ruler on the same axis */
  var mult=["","2×","4×","8×","16×","32×","64×"];
  for(var v=0;v<=24;v+=4){
    S("path",{d:"M"+X(v)+","+Tp+" L"+X(v)+","+(Tp+ph),class:"gridline"},svg);
    T(svg,X(v),Tp+ph+20,v+(v===24?" in":""),"tick",{"text-anchor":"middle"});
    if(v>0) T(svg,X(v),Tp-10,mult[v/4],"tick",{"text-anchor":"middle"});
  }
  T(svg,L,Tp-30,"HOW MUCH MORE OFTEN A LOW-LYING SPOT FLOODS  (RULE OF THUMB)","axtitle");
  T(svg,L,Tp+ph+38,"INCHES ABOVE A NORMAL HIGH TIDE","axtitle");
  S("path",{d:"M"+L+","+Tp+" L"+L+","+(Tp+ph),class:"axisline"},svg);

  STACK.rows.forEach(function(row,ri){
    var cy=Tp+rowH*ri+rowH/2, y=cy-bh/2, cursor=0;
    var t1=T(svg,L-18,cy-1,row.name,"dlabel",{"text-anchor":"end"});
    T(svg,L-18,cy+15,row.sub,"anno",{"text-anchor":"end"});
    STACK.keys.forEach(function(kk){
      var val=row[kk.k]; if(!val) return;
      var x=X(cursor), w=X(cursor+val)-x;
      var gap=cursor>0?2:0;
      var isLast=(cursor+val)>= (row.bg+row.wave+row.tide)-0.001;
      var d=roundedBar(x+gap,y,w-gap,bh,isLast?4:0);
      var rect=S("path",{d:d,fill:"var("+kk.cvar+")"},svg);
      if(w-gap>52){
        var lab=T(svg,x+gap+w/2-gap/2,y+bh/2+4.5,val+" in","dlabel",{"text-anchor":"middle"});
        lab.style.fill=kk.k==="bg"?"#ffffff":"#1a1a19";
        if(kk.k==="bg") lab.style.fill="#ffffff";
      }
      var hit=S("rect",{x:x,y:y-10,width:Math.max(w,10),height:bh+20,class:"hit"},svg);
      bindTip(hit,row.name+" — "+row.sub,[{value:val+" in",name:kk.label,color:cssv(kk.cvar)}],null,rect);
      cursor+=val;
    });
    var total=row.bg+row.wave+row.tide;
    var tt=T(svg,X(total)+14,cy+5,total+" in","dlabel");
    var risk=Math.pow(2,total/4);
    T(svg,X(total)+14,cy+21,"≈"+(risk<10?risk.toFixed(1):Math.round(risk))+"× flood frequency","anno");
  });
}
function roundedBar(x,y,w,h,r){
  if(w<=0) return "M0,0";
  r=Math.min(r,w,h/2);
  return "M"+x+","+y+" H"+(x+w-r)+" A"+r+","+r+" 0 0 1 "+(x+w)+","+(y+r)
       +" V"+(y+h-r)+" A"+r+","+r+" 0 0 1 "+(x+w-r)+","+(y+h)+" H"+x+" Z";
}

/* ===================== EVENTS BAR CHART ===================== */
function renderEvents(){
  var svg=document.getElementById("eventsChart"); svg.innerHTML="";
  var W=1000,Hh=300,L=130,R=110,Tp=34,B=52;
  svg.setAttribute("viewBox","0 0 "+W+" "+Hh);
  var pw=W-L-R, ph=Hh-Tp-B, xmax=3.2;
  var X=function(v){return L+pw*v/xmax;};
  var rowH=ph/EVENTS.length, bh=22;

  for(var v=0;v<=3;v+=0.5){
    S("path",{d:"M"+X(v)+","+Tp+" L"+X(v)+","+(Tp+ph),class:"gridline"},svg);
    T(svg,X(v),Tp+ph+20,"+"+v.toFixed(1),"tick",{"text-anchor":"middle"});
  }
  T(svg,L,Tp+ph+38,"PEAK NIÑO 3.4 ANOMALY (°C)","axtitle");
  S("path",{d:"M"+L+","+Tp+" L"+L+","+(Tp+ph),class:"axisline"},svg);

  /* 'very strong' threshold */
  var tx=X(2.0);
  S("path",{d:"M"+tx+","+(Tp-6)+" L"+tx+","+(Tp+ph),stroke:"var(--axis)","stroke-width":1.5,fill:"none"},svg);
  T(svg,tx+6,Tp-10,"VERY STRONG ≥ +2.0 °C","annoK");

  EVENTS.forEach(function(e,i){
    var cy=Tp+rowH*i+rowH/2, y=cy-bh/2;
    var col=e.hi?"var(--series-2)":"var(--muted)";
    var bar=S("path",{d:roundedBar(L,y,X(e.v)-L,bh,4),fill:col},svg);
    var nm=T(svg,L-16,cy+5,e.name,"dlabel",{"text-anchor":"end"});
    if(e.hi){ T(svg,L-16,cy+20,"forecast","anno",{"text-anchor":"end"}); nm.setAttribute("y",cy-1); }
    T(svg,X(e.v)+12,cy+5,"+"+e.v.toFixed(1)+" °C","dlabel"+(e.hi?"":" sec"));
    var hit=S("rect",{x:L,y:y-8,width:X(e.v)-L,height:bh+16,class:"hit"},svg);
    bindTip(hit,e.name+(e.hi?" (forecast)":""),[{value:"+"+e.v.toFixed(1)+" °C",name:"peak Niño 3.4",color:cssv(e.hi?"--series-2":"--muted")}],e.note,bar);
  });
}

/* ===================== WORLD MAP ===================== */
var RC={dry:"--dry",wet:"--wet",oth:"--muted"};
var RLABEL={dry:"Drier than normal",wet:"Wetter than normal",oth:"Other signal"};
function renderWorld(){
  var m=MAPS.world, svg=document.getElementById("worldmap"); svg.innerHTML="";
  svg.setAttribute("viewBox","0 0 "+m.w+" "+m.h);
  S("rect",{x:0,y:0,width:m.w,height:m.h,rx:8,fill:"var(--ocean)"},svg);
  S("path",{d:m.d,class:"land",fill:"var(--land)",stroke:"var(--land-line)"},svg);

  var eq=proj(m,0,0);
  S("path",{d:"M0,"+eq[1]+" L"+m.w+","+eq[1],stroke:"var(--axis)","stroke-width":1,fill:"none"},svg);
  T(svg,8,eq[1]-7,"EQUATOR","annoK");
  var a=proj(m,-170,5), b=proj(m,-120,-5);
  S("rect",{x:a[0],y:a[1],width:b[0]-a[0],height:b[1]-a[1],rx:2,fill:"none",stroke:"var(--series-2)","stroke-width":1.5},svg);
  var nl=T(svg,(a[0]+b[0])/2,a[1]-8,"NIÑO 3.4: +2.7 °C","annoK",{"text-anchor":"middle"});
  nl.style.fill="var(--series-2)";
  nl.setAttribute("paint-order","stroke");nl.style.stroke="var(--ocean)";nl.setAttribute("stroke-width","3");

  REGIONS.forEach(function(r){
    var p=proj(m,r.lon,r.lat), col="var("+RC[r.c]+")";
    S("circle",{cx:p[0],cy:p[1],r:9.5,fill:"var(--surface-1)"},svg);
    var dot = r.c==="oth"
      ? S("circle",{cx:p[0],cy:p[1],r:7,fill:"none",stroke:col,"stroke-width":2.5},svg)
      : S("circle",{cx:p[0],cy:p[1],r:7,fill:col},svg);
    var t=T(svg,p[0]+r.dx,p[1]+r.dy,r.n,"dlabel",{"text-anchor":r.a});
    t.setAttribute("paint-order","stroke");t.style.stroke="var(--surface-1)";
    t.setAttribute("stroke-width","3.5");t.setAttribute("stroke-linejoin","round");
    var hit=S("circle",{cx:p[0],cy:p[1],r:20,class:"hit"},svg);
    bindTip(hit,r.n,[{value:RLABEL[r.c],name:"",color:cssv(RC[r.c])}],r.d,dot);
  });
}

/* ===================== TABLES + LEGENDS ===================== */
function renderTables(){
  buildTable("journeyTable",
    [{label:"Month",key:"m"},{label:"Where",key:"where"},{label:"In. above normal",key:"vv",num:true},
     {label:"Reported range",key:"rng",num:true},{label:"Basis",key:"basis"},{label:"Note",key:"note"}],
    JOURNEY.map(function(d){return {m:d.m,where:d.where,vv:d.v.toFixed(1),
      rng:d.lo!=null?d.lo+"–"+d.hi:"—",
      basis:d.kind==="obs"?"reported":(d.kind==="fc"?"forecast":"est. (interpolated)"),note:d.note};}));

  legend("journeyKey",[
    {color:cssv("--series-1"),label:"Reported observation",shape:"swdot"},
    {color:"var(--surface-1)",label:"Interpolated estimate (hollow)",shape:"swdot"},
    {color:"color-mix(in srgb, "+cssv("--series-1")+" 22%, transparent)",label:"Reported / forecast range",shape:"sw"}]);
  legend("stackLegend",STACK.keys.map(function(k){return {color:cssv(k.cvar),label:k.label};}));
  var srows=[];
  STACK.rows.forEach(function(r){
    STACK.keys.forEach(function(k){ if(r[k.k]) srows.push({when:r.name,comp:k.label,val:r[k.k],col:cssv(k.cvar)}); });
    srows.push({when:r.name,comp:"Total above a normal high tide",val:r.bg+r.wave+r.tide,col:""});
  });
  buildTable("stackTable",
    [{label:"Moment",key:"when"},{label:"Component",key:"comp",swatch:"col"},{label:"Inches",key:"val",num:true}],srows);

  buildTable("eventsTable",
    [{label:"Event",key:"name"},{label:"Peak Niño 3.4 (°C)",key:"vv",num:true},{label:"Note",key:"note"}],
    EVENTS.map(function(e){return {name:e.name+(e.hi?" (forecast)":""),vv:"+"+e.v.toFixed(1),note:e.note};}));

  legend("worldLegend",[
    {color:cssv("--dry"),label:"Drier than normal",shape:"swdot"},
    {color:cssv("--wet"),label:"Wetter than normal",shape:"swdot"},
    {color:cssv("--muted"),label:"Other signal (hollow marker)",shape:"swdot"}]);
  buildTable("worldTable",
    [{label:"Region",key:"n",swatch:"col"},{label:"Signal",key:"sig"},{label:"What that means",key:"d"}],
    REGIONS.map(function(r){return {n:r.n,sig:RLABEL[r.c],d:r.d,col:cssv(RC[r.c])};}));
}

/* ===================== BOOT ===================== */
function renderAll(){
  try{
    renderXsec(); renderPacific(); renderJourney();
    renderStack(); renderEvents(); renderWorld(); renderTables();
  }catch(err){ console.error(err); }
}
if(window.matchMedia&&window.matchMedia("(prefers-color-scheme: dark)").matches){ setTheme(true); }
else { renderAll(); }
})();
</script>
</body>
</html>
