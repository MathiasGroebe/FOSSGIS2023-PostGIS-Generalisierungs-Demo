
-- angrenzende Gebäude zusammenfassen
DROP TABLE IF EXISTS map.building;
CREATE TABLE map.building AS
WITH
clustering AS ( -- angrenzende Flächen finden
	SELECT ST_ClusterDBSCAN(geom, 0, 1) OVER() AS cluster_id, geom
	FROM building
),
dissolve AS ( -- Flächen zusammenfassen
	SELECT ST_Union(geom) AS geom
	FROM clustering
	GROUP BY cluster_id
) -- Speicherung mit ID
SELECT ROW_NUMBER() OVER() AS fid, geom
FROM dissolve;
CREATE INDEX map_building_geom ON map.building USING gist(geom); 
ALTER TABLE map.building ADD PRIMARY KEY (fid);

-- Gebäude mittels Buffer vereinfachen
DROP TABLE IF EXISTS map.building_simple;
CREATE TABLE map.building_simple AS
WITH 
buffer_simplify AS ( -- Vereinfachung mittel Buffer
	SELECT fid, ST_Buffer(ST_Buffer(ST_Buffer(ST_Buffer(geom, -3, 'endcap=flat join=mitre'), 1, 'endcap=flat join=mitre'), 5, 'endcap=flat join=mitre'), -3, 'endcap=flat join=mitre') AS geom
	FROM map.building
),
simplify AS ( -- Reduzierung von Punkten und Vereinfachung 
	SELECT fid, ST_SimplifyVW(geom, 3) AS geom
	FROM buffer_simplify),
make_valid AS ( -- nur valide Gebäude verwenden
	SELECT fid, geom
	FROM simplify
	WHERE ST_IsEmpty(geom) = FALSE -- filtert kollabierte Geometrien
),
filter1 AS ( -- schmale und große Gebäude wieder hinzufügen
	SELECT fid, ST_SimplifyVW(geom, 3) AS geom
	FROM MAP.building b 
	WHERE NOT EXISTS (SELECT 1 FROM make_valid bs WHERE b.fid = bs.fid) AND ST_Area(geom) >= 100
),
filter2 AS ( -- kleine Gebäude als rotierte Quadrate hinzufügen
	SELECT fid, ST_Rotate(ST_Buffer(ST_Centroid(geom), 4, 'endcap=square'), radians(0 - feature_orientation(geom)), ST_Centroid(geom)) AS geom
	FROM MAP.building b 
	WHERE NOT EXISTS (SELECT 1 FROM make_valid bs WHERE b.fid = bs.fid) AND ST_Area(geom) < 100 AND ST_Area(geom) > 50
)
SELECT fid, geom -- Zusammenführen der Ergebnisse 
FROM make_valid
UNION ALL 
SELECT fid, geom 
FROM filter1
UNION ALL 
SELECT fid, geom 
FROM filter2;
CREATE INDEX map_building_simple_geom ON map.building_simple USING gist(geom); 
ALTER TABLE map.building_simple ADD PRIMARY KEY (fid);

