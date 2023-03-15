CREATE displacment.power_line_displaced AS
WITH
buffer_line AS ( -- Linien auf Signatur erweitern
	SELECT fid, ST_Buffer(geom, 10)::geometry(Polygon, 32638) AS geom
	FROM displacement.highway h
	WHERE highway IN ('secondary', 'tertiary', 'unclassified', 'residential')
),
dump_points AS ( -- Linien in einzelne Stützpunkt zerlegen
	SELECT fid, (ST_DumpPoints(geom)).* 
	FROM displacement.power_line 
),
single_points AS ( -- Punkte mit Linienid und Punktid versehen
	SELECT fid AS lid, path[1] AS pid, geom
	FROM dump_points
),
buffer_points AS ( -- Puffern der Linienstützpunkte
	SELECT lid, pid, geom AS p_geom, ST_Buffer(geom, 10) AS geom
	FROM single_points
),
conflict_points AS ( -- ermitteln wo es Verschneidung zwischen gepufferten Straßen und Stützpunkten gibt
	SELECT ROW_NUMBER() over() AS cid, p.lid, p.pid, p.geom AS b_geom, p_geom AS geom
	FROM buffer_line l, buffer_points p
	WHERE ST_Intersects(l.geom, p.geom)
),
conflict_areas AS ( -- Bereich um zuschneiden
	SELECT cid, pid, ST_Intersection(ST_Buffer(cp.geom, 50), bl.geom) AS geom 
	FROM buffer_line bl, conflict_points cp 
	WHERE ST_Intersects(cp.b_geom, bl.geom)
),
clustering_areas AS ( -- angrenzende Flächen finden
	SELECT pid, cid, ST_ClusterDBSCAN(geom, 0, 1) OVER() AS cluster_id, geom
	FROM conflict_areas
),
dissolve_areas AS ( -- Flächen zusammenfassen
	SELECT pid, cid, ST_Union(geom) AS geom
	FROM clustering_areas
	GROUP BY pid, cid, cluster_id
),
directions AS ( -- Richtung ermitteln
	SELECT cp.pid, cp.lid, ST_ShortestLine(cp.geom, ST_ExteriorRing(da.geom)) AS geom
	FROM dissolve_areas da, conflict_points cp
	WHERE cp.cid = da.cid
),
directions_new AS ( -- Verdrängung in die ermittelte Richtung
	SELECT d.pid, d.lid, direction_line(ST_Startpoint(d.geom), (30 + ST_Length(d.geom))::numeric, degrees(ST_Azimuth(ST_Startpoint(d.geom), ST_Endpoint(d.geom)))::NUMERIC + 180) AS geom
	FROM directions d, conflict_areas ca 

),
new_points AS ( -- neue Punkte erstellen
	SELECT lid, pid, ST_Endpoint(geom) AS geom
	FROM directions_new
),
merge_points AS ( -- neue Punkte mit Punkte bestehenden Punkten kombinieren
	SELECT lid, pid, geom
	FROM new_points
	UNION
	SELECT sp.lid, sp.pid, sp.geom
	FROM single_points sp
	WHERE NOT EXISTS (SELECT 1 FROM new_points np WHERE np.lid = sp.lid AND np.pid = sp.pid)
),
order_points AS ( -- Punkte sortieren
	SELECT *
	FROM merge_points
	order by lid, pid
),
make_lines AS ( -- Punkte wieder zu Linien zusammenbauen
	SELECT lid AS fid, ST_MakeLine(geom) AS geom
	FROM order_points
	GROUP BY fid
)

SELECT fid, geom 
FROM make_lines;
CREATE INDEX displacement_power_line_displaced ON displacement.power_line_displaced USING gist(geom);
ALTER TABLE displacement.power_line_displaced ADD PRIMARY KEY (fid);


