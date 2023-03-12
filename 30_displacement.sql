-- Wegweiser puffern um Signaturen nachzubilden
DROP TABLE IF EXISTS displacement.guidepost_signature;
CREATE TABLE displacement.guidepost_signature AS
SELECT fid, ST_Buffer(geom, 25, 'endcap=square')::geometry(Polygon, 32638) AS geom
FROM displacement.guidepost g;
CREATE INDEX displacement_guidepost_signature ON displacement.guidepost_signature USING gist(geom);
ALTER TABLE displacement.guidepost_signature ADD PRIMARY KEY (fid);

-- Straßen und Wege puffern um Signaturen nachzubilden
DROP TABLE IF EXISTS displacement.highway_signature;
CREATE TABLE displacement.highway_signature AS
SELECT fid, ST_Buffer(geom, 20)::geometry(Polygon, 32638) AS geom
FROM displacement.highway h;
CREATE INDEX displacement_highway_signature ON displacement.highway_signature USING gist(geom);
ALTER TABLE displacement.highway_signature ADD PRIMARY KEY (fid);

-- Konflikte finden und Bereich darum maskieren und Flächen zusammenfassen
DROP TABLE IF EXISTS displacement.highway_guidepost_conflict;
CREATE TABLE displacement.highway_guidepost_conflict AS 
WITH
find_intersection AS ( -- Konflikte finden und Bereich darum maskieren
	SELECT gs.fid AS g_fid, ST_Intersection(ST_Buffer(gs.geom, 100), hs.geom) AS geom
	FROM displacement.highway_signature hs JOIN displacement.guidepost_signature gs ON ST_Intersects(hs.geom, gs.geom)
	),
clustering AS ( -- angrenzende Flächen finden
	SELECT g_fid, ST_ClusterDBSCAN(geom, 0, 1) OVER() AS cluster_id, geom
	FROM find_intersection
),
dissolve AS ( -- Flächen zusammenfassen
	SELECT g_fid, ST_Union(geom) AS geom
	FROM clustering
	GROUP BY g_fid, cluster_id
)
SELECT ROW_NUMBER() over() AS fid, g_fid, geom
FROM dissolve;
CREATE INDEX displacement_highway_guidepost_conflict ON displacement.highway_guidepost_conflict USING gist(geom);
ALTER TABLE displacement.highway_guidepost_conflict ADD PRIMARY KEY (fid);

-- Richtung der Verdränung mittels kürzester Linie zur Konfliktfläche ermitteln
DROP TABLE IF EXISTS displacement.highway_guidepost_direction;
CREATE TABLE displacement.highway_guidepost_direction AS 
SELECT ROW_NUMBER() over() AS fid, hgc.g_fid, ST_ShortestLine(g.geom, ST_ExteriorRing(hgc.geom)) AS geom
FROM displacement.highway_guidepost_conflict hgc, displacement.guidepost g 
WHERE hgc.g_fid = g.fid;
CREATE INDEX displacement_highway_guidepost_direction ON displacement.highway_guidepost_direction USING gist(geom);
ALTER TABLE displacement.highway_guidepost_direction ADD PRIMARY KEY (fid);

-- Verschiebung anhand der Richtung der kürzesten Linie, minimalen Abstand herstellen
DROP TABLE IF EXISTS displacement.highway_guidepost_direction_new;
CREATE TABLE displacement.highway_guidepost_direction_new AS 
SELECT fid, g_fid, direction_line(ST_Startpoint(geom), (30 + ST_Length(geom))::numeric, degrees(ST_Azimuth(ST_Startpoint(geom), ST_Endpoint(geom)))::numeric) AS geom
FROM displacement.highway_guidepost_direction;
CREATE INDEX displacement_highway_guidepost_direction_new ON displacement.highway_guidepost_direction_new USING gist(geom);
ALTER TABLE displacement.highway_guidepost_direction_new ADD PRIMARY KEY (fid);

-- Verdrängte und nicht verdrängte Wegweiser zusammenführen
DROP TABLE IF EXISTS displacement.guidepost_displaced;
CREATE TABLE displacement.guidepost_displaced AS 
SELECT g_fid AS fid, ST_Endpoint(geom) AS geom
FROM displacement.highway_guidepost_direction_new
UNION ALL 
SELECT fid, geom 
FROM displacement.guidepost g 
WHERE NOT EXISTS (SELECT 1 FROM displacement.highway_guidepost_direction_new hgdn WHERE hgdn.g_fid = g.fid);
CREATE INDEX displacement_guidepost_displaced ON displacement.guidepost_displaced USING gist(geom);
ALTER TABLE displacement.guidepost_displaced ADD PRIMARY KEY (fid);
