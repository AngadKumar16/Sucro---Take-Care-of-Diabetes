# The numbers and map in shot 2d. Rerun to check them:
#   python3 district-stat.py
# Adults with diagnosed diabetes in Texas's 22nd congressional district (119th Congress):
# CDC PLACES census-tract estimates (2025 release, 2023 BRFSS data, crude prevalence among adults),
# times each tract's adult population, summed over the tracts in the district (split tracts are
# weighted by the share of their land area inside it, from the Census tract-to-district file).
# Also rewrites scenes/geo.js with the Texas and district outlines from Census TIGERweb.
import io, json, os, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
get = lambda url: urllib.request.urlopen(url, timeout=120).read()

rel = get("https://www2.census.gov/geo/docs/maps-data/data/rel2020/cd-sld/tab20_cd11920_tract20_natl.txt").decode("utf-8-sig").splitlines()
head = rel[0].split("|"); ix = {k: i for i, k in enumerate(head)}
share = {}
for line in rel[1:]:
    r = line.split("|")
    if r[ix["GEOID_CD119_20"]] == "4822":
        land = int(r[ix["AREALAND_TRACT_20"]])
        share[r[ix["GEOID_TRACT_20"]]] = int(r[ix["AREALAND_PART"]]) / land if land else 0

places = json.loads(get("https://data.cdc.gov/resource/cwsq-ngmh.json?stateabbr=TX&measureid=DIABETES&$limit=10000"))
by_tract = {p["locationname"]: p for p in places}
adults = diabetes = 0
for tract, f in share.items():
    p = by_tract.get(tract)
    if not p or f < 0.001: continue
    a = float(p["totalpop18plus"]) * f
    adults += a
    diabetes += a * float(p["data_value"]) / 100
print(f"TX-22: {round(adults):,} adults, {round(diabetes):,} with diagnosed diabetes ({diabetes / adults:.1%}); PLACES data year {places[0]['year']}")

def geo(url):
    g = json.loads(get(url))["features"][0]["geometry"]
    rings = [g["coordinates"][0]] if g["type"] == "Polygon" else [p[0] for p in g["coordinates"]]
    return max(rings, key=len)
tw = "https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/"
texas = geo(tw + "State_County/MapServer/0/query?where=STUSAB%3D%27TX%27&outSR=4326&maxAllowableOffset=0.05&f=geojson")
tx22 = geo(tw + "Legislative/MapServer/4/query?where=GEOID%3D%274822%27&outSR=4326&maxAllowableOffset=0.005&f=geojson")
r = lambda pts, n: [[round(x, n), round(y, n)] for x, y in pts]
# Every state for the zoom out to the whole country, with Alaska and Hawaii moved and scaled into
# the usual insets (territories left out).
us = []
for f in json.loads(get(tw + "State_County/MapServer/0/query?where=1%3D1&outFields=STUSAB&outSR=4326&maxAllowableOffset=0.08&f=geojson"))["features"]:
    st, g = f["properties"]["STUSAB"], f["geometry"]
    if st in ("AS", "GU", "MP", "PR", "VI"): continue
    for ring in ([g["coordinates"][0]] if g["type"] == "Polygon" else [p[0] for p in g["coordinates"]]):
        if len(ring) < 4: continue
        if st == "AK":
            if any(x > 0 for x, _ in ring): continue
            ring = [[-117 + (x + 152) * 0.32, 25 + (y - 62) * 0.32 * 1.4] for x, y in ring]
        if st == "HI":
            ring = [[-106 + (x + 157), 25.5 + (y - 20.5)] for x, y in ring]
        us.append(r(ring, 2))
with open(os.path.join(HERE, "scenes", "geo.js"), "w") as f:
    f.write("// Outlines for shot 2d, from the Census TIGERweb service (lon, lat): Texas, and Texas's 22nd\n"
            "// congressional district as drawn for the 119th Congress. Rebuild with `python3 district-stat.py`.\n"
            "export const GEO = " + json.dumps({"texas": r(texas, 2), "tx22": r(tx22, 3), "us": us}, separators=(",", ":")) + ";\n")
