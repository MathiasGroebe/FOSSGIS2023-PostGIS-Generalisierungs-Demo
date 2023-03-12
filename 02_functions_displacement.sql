
CREATE OR REPLACE FUNCTION direction_line(point geometry, length numeric, azimuth numeric) RETURNS geometry AS
$$
declare
B geometry;

BEGIN

	B:= ST_Translate(point, - sin(radians(azimuth + 180)) * length, - cos(radians(azimuth + 180)) * length);
	RETURN ST_MakeLine(point, B);

END;
$$ LANGUAGE plpgsql PARALLEL SAFE;