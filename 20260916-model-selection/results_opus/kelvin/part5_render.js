
/* ===================== CROSS SECTION ===================== */
var xsecState="normal";
var XS={
 normal:{
  thermo:"M 90,258 C 260,252 380,240 500,218 C 620,196 720,172 820,157 C 880,149 930,145 960,143",
  surf:  "M 90,96 C 260,97 380,98 500,99 C 620,100 720,101 820,102 C 880,103 930,104 960,104",
  note:"Easterly trade winds pile warm water in the west, so the warm layer is ~150 m deep near Indonesia and only ~50 m deep off South America. Cold water upwells freely along the eastern equator — this is the ocean's default state, and La Niña is an exaggeration of it."
 },
 wave:{
  thermo:"M 90,206 C 260,205 380,212 500,226 C 620,240 720,254 820,259 C 880,261 930,259 960,256",
  surf:  "M 90,101 C 260,101 380,99 500,96 C 620,93 720,90 820,88 C 880,87 930,87 960,88",
  note:"A westerly wind burst relaxes the trades and launches a downwelling Kelvin wave east. Where it passes, the thermocline is pushed down tens of metres, cold upwelling is cut off, the surface warms — and sea level rises by about a foot. Repeat this a few times and you have built an El Niño."
 }
};
function renderXsec(){
  var svg=document.getElementById("xsec"); svg.innerHTML="";
  var st=XS[xsecState];
  var x0=90,x1=960,ySurf=96,yBed=372;
  function lx(lon){return x0+(lon-120)/160*(x1-x0);} /* lon in 0..360, 120E..280(80W) */

  /* water body */
  S("rect",{x:x0,y:ySurf,width:x1-x0,height:yBed-ySurf,fill:"var(--ocean)",rx:2},svg);
  /* cold deep water wash */
  S("path",{d:st.thermo+" L960,"+yBed+" L90,"+yBed+" Z",fill:"var(--wash)"},svg);
  /* warm layer wash */
  S("path",{d:st.thermo+" L960,"+ySurf+" L90,"+ySurf+" Z",fill:"var(--warmwash)"},svg);

  var surf=S("path",{d:st.surf,fill:"none",stroke:"var(--series-1)","stroke-width":2,"stroke-linecap":"round"},svg);
  var th=S("path",{d:st.thermo,fill:"none",stroke:"var(--series-2)","stroke-width":2.5,"stroke-linecap":"round"},svg);
  surf.style.transition="d .55s cubic-bezier(.4,0,.2,1)";
  th.style.transition="d .55s cubic-bezier(.4,0,.2,1)";

  /* sea floor */
  S("path",{d:"M"+x0+","+yBed+" L"+x1+","+yBed,stroke:"var(--axis)","stroke-width":1.5,fill:"none"},svg);

  /* labels on the two curves */
  T(svg,x0+8,ySurf-12,"Sea surface (height exaggerated)","anno");
  T(svg,x1-8,(xsecState==="normal"?154:250)-12,"Thermocline — the warm / cold boundary","anno",{"text-anchor":"end"});

  /* geography ticks */
  var geo=[[120,"120°E"],[150,"Warm pool"],[180,"Date line"],[210,"150°W"],[240,"120°W"],[272,"Galápagos"]];
  geo.forEach(function(g){
    var x=lx(g[0]);
    S("path",{d:"M"+x+","+yBed+" L"+x+","+(yBed+6),stroke:"var(--axis)","stroke-width":1,fill:"none"},svg);
    T(svg,x,yBed+21,g[1],"tick",{"text-anchor":g[0]===120?"start":(g[0]>=272?"end":"middle")});
  });
  T(svg,x0,yBed+42,"Indonesia","annoK");
  T(svg,x1,yBed+42,"Peru / Ecuador","annoK",{"text-anchor":"end"});

  /* depth scale: linear to 200 m, compressed below */
  [[0,96],[100,200],[200,304]].forEach(function(t){
    S("path",{d:"M"+(x0-6)+","+t[1]+" L"+x0+","+t[1],stroke:"var(--axis)","stroke-width":1,fill:"none"},svg);
    T(svg,x0-11,t[1]+4,t[0]+" m","tick",{"text-anchor":"end"});
  });
  S("path",{d:"M"+(x0-4)+",332 l8,-5 l-8,-5 M"+(x0-4)+",344 l8,-5 l-8,-5",
    stroke:"var(--axis)","stroke-width":1.5,fill:"none"},svg);
  T(svg,x0-11,yBed+4,"~4 km","tick",{"text-anchor":"end"});
  T(svg,x0-11,yBed+18,"sea floor","anno",{"text-anchor":"end"});

  /* wind arrows */
  var g=S("g",{},svg);
  if(xsecState==="normal"){
    for(var i=0;i<5;i++){
      var ax=lx(150+i*28);
      arrow(g,ax+46,62,ax,62,"var(--muted)",1.8);
    }
    T(svg,lx(214),50,"Easterly trade winds","anno",{"text-anchor":"middle"});
    upwell(svg,lx(272),true);
  }else{
    for(var j=0;j<4;j++){
      var bx=lx(132+j*24);
      arrow(g,bx,62,bx+40,62,"var(--series-2)",2.2);
    }
    T(svg,lx(168),50,"Westerly wind burst","anno",{"text-anchor":"start"});
    upwell(svg,lx(272),false);
    /* travelling wave annotation */
    arrow(svg,lx(200),300,lx(250),300,"var(--series-2)",2.2);
    T(svg,lx(225),322,"wave travels east at 2–3 m/s","anno",{"text-anchor":"middle"});
    T(svg,lx(225),340,"≈ 2 months to cross","annoK",{"text-anchor":"middle"});
    /* surface bulge callout */
    S("path",{d:"M"+lx(258)+",78 L"+lx(258)+",90",stroke:"var(--series-1)","stroke-width":1.5,fill:"none"},svg);
    T(svg,lx(258),72,"↑ ~12 in of extra water","anno",{"text-anchor":"middle"});
  }
  document.getElementById("xsecNote").textContent=st.note;
}
function arrow(p,x1,y1,x2,y2,col,w){
  S("path",{d:"M"+x1+","+y1+" L"+x2+","+y2,stroke:col,"stroke-width":w,fill:"none","stroke-linecap":"round"},p);
  var dir=x2>x1?1:-1;
  S("path",{d:"M"+x2+","+y2+" L"+(x2-7*dir)+","+(y2-4)+" L"+(x2-7*dir)+","+(y2+4)+" Z",fill:col},p);
}
function upwell(p,x,on){
  var col=on?"var(--series-1)":"var(--muted)";
  var g=S("g",{},p);
  if(!on) g.style.opacity="0.45";
  [0,1,2].forEach(function(i){
    var xx=x+i*22;
    S("path",{d:"M"+xx+",300 L"+xx+",200",stroke:col,"stroke-width":2,fill:"none","stroke-linecap":"round"},g);
    S("path",{d:"M"+xx+",200 L"+(xx-4)+",208 L"+(xx+4)+",208 Z",fill:col},g);
  });
  T(g,x+22,326,on?"cold upwelling":"upwelling shut off","anno",{"text-anchor":"middle"});
  if(!on){
    S("path",{d:"M"+(x-14)+",324 L"+(x+58)+",190",stroke:"var(--dry)","stroke-width":2.5,fill:"none","stroke-linecap":"round"},p);
  }
}
document.getElementById("stNormal").addEventListener("click",function(){setXsec("normal");});
document.getElementById("stWave").addEventListener("click",function(){setXsec("wave");});
function setXsec(s){
  xsecState=s;
  document.getElementById("stNormal").setAttribute("aria-pressed",s==="normal");
  document.getElementById("stWave").setAttribute("aria-pressed",s==="wave");
  renderXsec();
}

/* ===================== PACIFIC MAP ===================== */
function renderPacific(){
  var m=MAPS.pacific, svg=document.getElementById("pacmap"); svg.innerHTML="";
  svg.setAttribute("viewBox","0 0 "+m.w+" "+m.h);
  S("rect",{x:0,y:0,width:m.w,height:m.h,rx:8,fill:"var(--ocean)"},svg);
  S("path",{d:m.d,class:"land",fill:"var(--land)",stroke:"var(--land-line)"},svg);

  /* equator + Nino 3.4 box */
  var eqL=proj(m,95.5,0), eqR=proj(m,289.5,0);
  S("path",{d:"M"+eqL[0]+","+eqL[1]+" L"+eqR[0]+","+eqR[1],stroke:"var(--axis)","stroke-width":1,fill:"none"},svg);
  T(svg,14,eqL[1]-7,"EQUATOR","annoK");
  var a=proj(m,190,5), b=proj(m,240,-5);
  S("rect",{x:a[0],y:a[1],width:b[0]-a[0],height:b[1]-a[1],rx:3,fill:"none",
    stroke:"var(--muted)","stroke-width":1},svg);
  T(svg,(a[0]+b[0])/2,b[1]+16,"NIÑO 3.4 INDEX REGION","annoK",{"text-anchor":"middle"});

  /* route */
  var eq=ROUTE_EQ.map(function(p){return proj(m,p[0],p[1]);});
  var co=ROUTE_CO.map(function(p){return proj(m,p[0],p[1]);});
  var dEq=smooth(eq), dCo=smooth(co);
  [dEq,dCo].forEach(function(d){
    S("path",{d:d,fill:"none",stroke:"var(--surface-1)","stroke-width":9,"stroke-linecap":"round",opacity:.85},svg);
  });
  S("path",{d:dEq,fill:"none",stroke:"var(--series-2)","stroke-width":3.5,"stroke-linecap":"round"},svg);
  var coP=S("path",{d:dCo,fill:"none",stroke:"var(--series-2)","stroke-width":3.5,"stroke-linecap":"round"},svg);
  coP.style.opacity="0.6";

  /* direction arrowheads */
  [[eq,3],[eq,7],[co,4],[co,9]].forEach(function(q){
    var pts=q[0],i=q[1];
    var p1=pts[i],p2=pts[i+1];
    var ang=Math.atan2(p2[1]-p1[1],p2[0]-p1[0]);
    var g=S("g",{transform:"translate("+p2[0].toFixed(1)+","+p2[1].toFixed(1)+") rotate("+(ang*180/Math.PI).toFixed(1)+")"},svg);
    S("path",{d:"M0,0 L-9,-5.5 L-9,5.5 Z",fill:"var(--series-2)"},g);
  });

  /* stops */
  STOPS.forEach(function(s,i){
    var p=proj(m,s.lon,s.lat);
    var r=s.big?8:6.5;
    S("circle",{cx:p[0],cy:p[1],r:r+2.5,fill:"var(--surface-1)"},svg);
    var c=S("circle",{cx:p[0],cy:p[1],r:r,fill:s.big?"var(--series-2)":"var(--surface-1)",
      stroke:"var(--series-2)","stroke-width":2.5},svg);
    var lx=p[0]+s.dx, ly=p[1]+s.dy;
    var t1=T(svg,lx,ly,s.date,"dlabel",{"text-anchor":s.anchor});
    var t2=T(svg,lx,ly+15,s.place,"dlabel sec",{"text-anchor":s.anchor});
    /* halo behind text for legibility */
    [t1,t2].forEach(function(t){t.setAttribute("paint-order","stroke");t.style.stroke="var(--surface-1)";
      t.setAttribute("stroke-width","4");t.setAttribute("stroke-linejoin","round");});
    var hit=S("circle",{cx:p[0],cy:p[1],r:22,class:"hit"},svg);
    bindTip(hit,s.date+" · "+s.place,[],s.txt,c);
  });
}

/* ===================== JOURNEY LINE CHART ===================== */
function renderJourney(){
  var svg=document.getElementById("journeyChart"); svg.innerHTML="";
  var W=1000,Hh=360,L=54,R=22,Tp=26,B=64;
  svg.setAttribute("viewBox","0 0 "+W+" "+Hh);
  var pw=W-L-R, ph=Hh-Tp-B, ymax=16;
  var X=function(i){return L+pw*i/(JOURNEY.length-1);};
  var Y=function(v){return Tp+ph-(v/ymax)*ph;};

  /* forecast region */
  S("rect",{x:X(7),y:Tp,width:X(11)-X(7)+18,height:ph,fill:"var(--wash)",rx:4},svg);
  T(svg,X(7)+8,Tp+14,"FORECAST","annoK");

  /* gridlines */
  for(var v=0;v<=ymax;v+=4){
    S("path",{d:"M"+L+","+Y(v)+" L"+(W-R)+","+Y(v),class:"gridline"},svg);
    T(svg,L-10,Y(v)+4,v,"tick",{"text-anchor":"end"});
  }
  T(svg,L-10,Tp-10,"INCHES ABOVE NORMAL","axtitle",{"text-anchor":"start"});

  /* range band where reported */
  var banded=JOURNEY.map(function(d,i){return d.lo!=null?i:-1;}).filter(function(i){return i>=0;});
  if(banded.length){
    var top=[],bot=[];
    banded.forEach(function(i){top.push([X(i),Y(JOURNEY[i].hi)]);bot.unshift([X(i),Y(JOURNEY[i].lo)]);});
    var poly=function(a){return a.map(function(q){return q[0].toFixed(1)+","+q[1].toFixed(1);}).join(" L");};
    var dBand="M"+poly(top)+" L"+poly(bot)+" Z";
    S("path",{d:dBand,fill:"var(--series-1)",opacity:.14},svg);
  }

  /* line */
  var pts=JOURNEY.map(function(d,i){return [X(i),Y(d.v)];});
  S("path",{d:smooth(pts),fill:"none",stroke:"var(--series-1)","stroke-width":2,
    "stroke-linecap":"round","stroke-linejoin":"round"},svg);

  /* x axis */
  S("path",{d:"M"+L+","+(Tp+ph)+" L"+(W-R)+","+(Tp+ph),class:"axisline"},svg);
  JOURNEY.forEach(function(d,i){
    T(svg,X(i),Tp+ph+20,d.m.split(" ")[0],"tick",{"text-anchor":"middle"});
    if(d.m.indexOf("Mar 2026")===0||d.m.indexOf("Jan 2027")===0)
      T(svg,X(i),Tp+ph+36,d.m.split(" ")[1],"tick",{"text-anchor":"middle"});
  });

  /* markers */
  JOURNEY.forEach(function(d,i){
    var p=pts[i];
    S("circle",{cx:p[0],cy:p[1],r:6.5,fill:"var(--surface-1)"},svg);
    var mk=S("circle",{cx:p[0],cy:p[1],r:4.5,
      fill:d.kind==="est"?"var(--surface-1)":"var(--series-1)",
      stroke:"var(--series-1)","stroke-width":2},svg);
    var hit=S("circle",{cx:p[0],cy:p[1],r:26,class:"hit"},svg);
    hit.__mark=null;
    var rows=[{value:d.v.toFixed(1)+" in",name:"above normal",color:cssv("--series-1")}];
    if(d.lo!=null) rows.push({value:d.lo+"–"+d.hi+" in",name:"reported range"});
    bindTip(hit,d.m+" · "+d.where,rows,d.note,mk);
  });

  /* selective direct labels */
  [[2,"5.9 in off Peru",-10,7,"end"],[6,"9–14 in, Central America",0,-26,"middle"],
   [7,"10–14 in, S. California",10,-16,"start"]].forEach(function(l){
    var i=l[0],p=pts[i];
    var t=T(svg,p[0]+l[2],p[1]+l[3],l[1],"dlabel",{"text-anchor":l[4]});
    t.setAttribute("paint-order","stroke");t.style.stroke="var(--surface-1)";
    t.setAttribute("stroke-width","4");t.setAttribute("stroke-linejoin","round");
  });
}
