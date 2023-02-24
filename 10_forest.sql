DROP TABLE IF EXISTS map.forest;
CREATE TABLE map.forest AS
WITH
expand AS ( -- erweitern um 10 m
	SELECT ST_Buffer(geom, 10) AS geom
	FROM forest
),
clustering AS ( -- überlappende und angrenzende Flächen finden
	SELECT ST_ClusterDBSCAN(geom, 0, 1) OVER() AS cluster_id, geom
	FROM expand
),
dissolve AS ( -- Flächen zusammenfassen
	SELECT ST_Union(geom) AS geom
	FROM clustering
	GROUP BY cluster_id
),
shrink AS ( -- auf usprünglichen Größe der Flächen zurückschrumpfen
	SELECT ST_Buffer(ST_Buffer(geom, -20), 10) AS geom
	FROM dissolve
),
single_feature AS ( -- Multipolygone in einzelene Polygone erlegen
	SELECT (ST_Dump(geom)).geom AS geom
	FROM shrink
),
min_area as ( -- Auswahl nach minimaler Fläche
	select *
	from single_feature
	WHERE ST_Area(geom) > 306
),
sieve as ( -- Löcher aus Flächen filtern
	select Sieve(geom, 156) as geom 
	from min_area
),
simplify as ( -- Linien der Flächen vereinfachen
	select ST_Simplify(geom, 5) AS geom
	from sieve
) -- Speicherung mit ID
SELECT ROW_NUMBER() OVER() AS fid, geom
FROM simplify;
CREATE INDEX map_forest_geom ON map.forest USING gist(geom); 
ALTER TABLE map.forest ADD PRIMARY KEY (fid);