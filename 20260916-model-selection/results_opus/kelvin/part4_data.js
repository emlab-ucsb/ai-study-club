
/* ===================== DATA ===================== */

var STOPS=[
 {lon:150,lat:5,date:"March 2026",place:"Western Pacific warm pool",
  txt:"Westerly wind bursts — often riding the Madden–Julian Oscillation — shove surface water east and press the thermocline down. The wave sets off, almost entirely below the surface.",
  dx:0,dy:-24,anchor:"middle",big:true},
 {lon:205,lat:0,date:"April 2026",place:"Niño 3.4 region",
  txt:"Crossing the central Pacific along the equatorial waveguide at 2–3 m/s. Satellite altimeters and the moored buoy array watch it as a shallow bulge in sea surface height.",
  dx:0,dy:-22,anchor:"middle"},
 {lon:277,lat:-6,date:"mid-May 2026",place:"Galápagos, Ecuador & Peru",
  txt:"Arrival. Seas around Peru run more than 5.9 in (15 cm) above the long-term average. Anchovy and sardine schools move north; blue-footed boobies turn up early in Panama.",
  dx:-14,dy:20,anchor:"end"},
 {lon:280.5,lat:9,date:"September 2026",place:"Central American coast",
  txt:"Now a coastal-trapped wave, held against the shelf by the Earth's rotation. Sea levels reported 9–14 in above normal along parts of the coast.",
  dx:-16,dy:24,anchor:"end"},
 {lon:255.7,lat:19,date:"mid-September 2026",place:"Off mainland Mexico",
  txt:"Travelling north at roughly 6 mph. Not a breaking wave and not a tsunami — a broad hump of elevated water that takes days to pass any one beach.",
  dx:6,dy:24,anchor:"start"},
 {lon:241.5,lat:34,date:"early October 2026",place:"Southern California",
  txt:"Projected arrival: sea level 10–14 in above normal from Malibu to San Clemente, with 3–6 months to relax — straight into king-tide and winter-storm season.",
  dx:-16,dy:-8,anchor:"end",big:true}
];
var ROUTE_EQ=[[148,5],[160,3],[172,1],[184,0],[196,0],[208,-1],[220,-1],[232,-2],[244,-3],[256,-4],[268,-4],[276,-5],[280,-6]];
var ROUTE_CO=[[280,-6],[281.2,-3],[280.8,1],[280.4,5],[280.6,9],[275,11],[268,14],[260,17],[255.7,19],[250,23],[246,28],[243,32.5],[241.5,34],[238,37.5]];

var JOURNEY=[
 {m:"Mar 2026",v:1.5,kind:"est",where:"W Pacific warm pool",note:"Wave launched; bulge still mostly subsurface"},
 {m:"Apr 2026",v:3.0,kind:"est",where:"Central Pacific",note:"Crossing the equatorial waveguide"},
 {m:"May 2026",v:5.9,kind:"obs",where:"Off Peru",note:"Reported: >5.9 in (15 cm) above average, Sentinel-6"},
 {m:"Jun 2026",v:7.0,kind:"est",where:"Eastern Pacific",note:"Successive waves reinforce the warming"},
 {m:"Jul 2026",v:8.0,kind:"est",where:"Eastern Pacific",note:"Niño 3.4 monthly value +2.03 °C"},
 {m:"Aug 2026",v:9.5,kind:"est",where:"Eastern Pacific",note:"Weekly Niño 3.4 reaches +2.7 °C on 12 Aug"},
 {m:"Sep 2026",v:11.5,lo:9,hi:14,kind:"obs",where:"Central America",note:"Reported: 9–14 in above normal"},
 {m:"Oct 2026",v:12.0,lo:10,hi:14,kind:"fc",where:"S. California",note:"Projected: 10–14 in above normal on arrival"},
 {m:"Nov 2026",v:11.0,lo:8,hi:13.5,kind:"fc",where:"S. California",note:"Relaxation begins; king tides start"},
 {m:"Dec 2026",v:9.0,lo:6,hi:12,kind:"fc",where:"S. California",note:"Peak winter storm season"},
 {m:"Jan 2027",v:7.0,lo:4,hi:10,kind:"fc",where:"S. California",note:"Highest astronomical tides of the year"},
 {m:"Feb 2027",v:5.0,lo:2,hi:8,kind:"fc",where:"S. California",note:"El Niño forecast to persist through this month"}
];

var STACK={
 keys:[{k:"bg",label:"El Niño background rise",cvar:"--series-1"},
       {k:"wave",label:"Kelvin wave pulse",cvar:"--series-2"},
       {k:"tide",label:"King tide above a typical high tide",cvar:"--series-3"}],
 rows:[
  {name:"Mid-September 2026",sub:"today",bg:4,wave:0,tide:0},
  {name:"Early October 2026",sub:"wave arrives",bg:4,wave:8,tide:0},
  {name:"January 2027",sub:"wave lingers under a king tide",bg:4,wave:6,tide:12}
 ]
};

var EVENTS=[
 {name:"2026–27",v:3.0,hi:true,note:"Forecast central estimate. Fifteen models reach or exceed +3.0 °C; a 75% chance of exceeding every event back to 1950."},
 {name:"2015–16",v:2.6,note:"Peak ONI. Produced a sequence of Kelvin waves and roughly a foot of extra sea level on the US West Coast."},
 {name:"1997–98",v:2.4,note:"Peak ONI. Catastrophic flooding in coastal Peru and Ecuador; a very wet California winter."},
 {name:"1982–83",v:2.1,note:"Peak ONI. The event that established the Kelvin-wave picture of El Niño onset."},
 {name:"2023–24",v:2.0,note:"Peak ONI. The most recent strong event before the multi-year La Niña that just ended."}
];

var REGIONS=[
 {lon:116,lat:-2,c:"dry",n:"Indonesia",d:"Drought and elevated wildfire risk as the tropical rainfall engine shifts east.",dx:0,dy:26,a:"middle"},
 {lon:122,lat:15,c:"dry",n:"Philippines",d:"Reduced rainfall and drought risk through the event.",dx:12,dy:-8,a:"start"},
 {lon:147,lat:-27,c:"dry",n:"E. Australia",d:"Rainfall deficits and elevated bushfire risk — the classic Australian El Niño signal.",dx:12,dy:4,a:"start"},
 {lon:79,lat:22,c:"dry",n:"India",d:"IMD puts the 2026 southwest monsoon at ~90% of the long-period average, with 60% odds of drought in the core monsoon zone. Late-June cumulative rainfall ran about 42% below normal.",dx:-12,dy:-6,a:"end"},
 {lon:26,lat:-20,c:"dry",n:"Southern Africa",d:"Below-normal rains expected through the southern wet season.",dx:0,dy:26,a:"middle"},
 {lon:39,lat:8,c:"dry",n:"Ethiopia & W. Kenya",d:"FEWS NET attributes the summer 2026 drought to this El Niño's early, intense onset. The October–December short rains typically flip wetter.",dx:12,dy:-6,a:"start"},
 {lon:-60,lat:-4,c:"dry",n:"N. Brazil & Amazon",d:"Drought across the northern Amazon; falling river levels.",dx:-14,dy:-10,a:"end"},
 {lon:-81,lat:9,c:"dry",n:"Panama & C. America",d:"The Panama Canal authority is restricting the number and size of transiting ships as freshwater inflow falls. Farmers in Panama and El Salvador have been unable to plant.",dx:-12,dy:-8,a:"end"},
 {lon:-79,lat:-7,c:"wet",n:"Peru & Ecuador coast",d:"The wave's landfall. A normally desert coast faces damaging rain and flooding; tuna are moving offshore and poleward, and crews travel farther to find them.",dx:-14,dy:26,a:"end"},
 {lon:-120,lat:38,c:"wet",n:"California",d:"Kelvin wave arrives early October, raising sea level 10–14 in. The wet winter signal ramps up later, peaking January–March 2027.",dx:-12,dy:-6,a:"end"},
 {lon:-87,lat:31,c:"wet",n:"US Gulf & Southeast",d:"Wetter than normal — with coastal California, the strongest US winter rainfall signal in the seasonal outlook.",dx:-12,dy:-10,a:"end"},
 {lon:-58,lat:-31,c:"wet",n:"SE South America",d:"Uruguay, northeast Argentina and southern Brazil trend wetter.",dx:-12,dy:20,a:"end"},
 {lon:-45,lat:17,c:"oth",n:"Atlantic hurricanes",d:"Suppressed. NOAA gave 55% odds of a below-average 2026 season: El Niño strengthens vertical wind shear across the basin, tearing storms apart before they organise.",dx:-12,dy:-10,a:"end"}
];
