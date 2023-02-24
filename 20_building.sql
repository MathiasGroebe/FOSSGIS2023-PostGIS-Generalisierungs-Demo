
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
SELECT fid, ST_Buffer(ST_Buffer(ST_Buffer(ST_Buffer(geom, -3, 'endcap=flat join=mitre'), 1, 'endcap=flat join=mitre'), 5, 'endcap=flat join=mitre'), -3, 'endcap=flat join=mitre') AS geom
FROM map.building;
CREATE INDEX map_building_simple_geom ON map.building_simple USING gist(geom); 
ALTER TABLE map.building_simple ADD PRIMARY KEY (fid);