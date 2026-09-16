import json, math

land = json.load(open('land110.json'))

def rings(feat):
    g = feat['geometry']; t = g['type']; c = g['coordinates']
    if t == 'Polygon': return c
    if t == 'MultiPolygon': return [r for poly in c for r in poly]
    return []

class Proj:
    """Equirectangular with a shiftable central meridian."""
    def __init__(self, lon0, lon_min, lon_max, lat_min, lat_max, width):
        self.lon0=lon0; self.lon_min=lon_min; self.lon_max=lon_max
        self.lat_min=lat_min; self.lat_max=lat_max
        self.width=width
        self.k = width/(lon_max-lon_min)
        self.height = (lat_max-lat_min)*self.k
    def wrap(self, lon):
        # shift into a continuous frame centred on lon0
        x = lon - self.lon0
        while x < -180: x += 360
        while x >= 180: x -= 360
        return x + self.lon0
    def xy(self, lon, lat):
        return ((self.wrap(lon)-self.lon_min)*self.k, (self.lat_max-lat)*self.k)

def paths(proj, simplify=0.35):
    out=[]
    for f in land['features']:
        for ring in rings(f):
            # split at antimeridian jumps
            segs=[[]]
            prev=None
            for lon,lat in ring:
                w=proj.wrap(lon)
                if prev is not None and abs(w-prev)>180:
                    segs.append([])
                segs[-1].append((w,lat)); prev=w
            for seg in segs:
                pts=[]
                for w,lat in seg:
                    x=(w-proj.lon_min)*proj.k; y=(proj.lat_max-lat)*proj.k
                    if pts and abs(x-pts[-1][0])<simplify and abs(y-pts[-1][1])<simplify: continue
                    pts.append((x,y))
                if len(pts)<3: continue
                # cull rings entirely outside the frame (with margin)
                xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
                if max(xs)< -20 or min(xs)>proj.width+20 or max(ys)< -20 or min(ys)>proj.height+20: continue
                d='M'+' L'.join(f'{x:.1f},{y:.1f}' for x,y in pts)+'Z'
                out.append(d)
    return out

# Map A: Pacific basin + Americas west coast
A = Proj(lon0=180, lon_min=95, lon_max=290, lat_min=-38, lat_max=52, width=1000)
# Map B: whole world, Pacific-centred
B = Proj(lon0=160, lon_min=-20, lon_max=340, lat_min=-58, lat_max=80, width=1000)

res={}
for name,p in (('pacific',A),('world',B)):
    ds=paths(p)
    res[name]={'d':' '.join(ds),'w':round(p.width,1),'h':round(p.height,1),
               'lon0':p.lon0,'lonMin':p.lon_min,'latMax':p.lat_max,'k':p.k}
    print(name, 'rings',len(ds), 'h',round(p.height,1), 'chars',len(res[name]['d']))

open('maps.json','w').write(json.dumps(res))

# sanity: a few landmark positions
for nm,(lo,la) in {'Los Angeles':(-118.4,33.9),'Lima':(-77,-12),'Panama':(-79.5,9),
                   'Darwin':(130.8,-12.4),'Jakarta':(106.8,-6.2),'Mumbai':(72.9,19.1),
                   'Nairobi':(36.8,-1.3),'Sydney':(151.2,-33.9),'Manila':(121,14.6),
                   'Galapagos':(-90.4,-0.7),'Nino3.4 W':(-170,0),'Nino3.4 E':(-120,0)}.items():
    print(f'{nm:14s} A={tuple(round(v,1) for v in A.xy(lo,la))}  B={tuple(round(v,1) for v in B.xy(lo,la))}')
