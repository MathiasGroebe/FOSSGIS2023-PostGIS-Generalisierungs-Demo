# FOSSGIS2023 PostGIS Generalisierungs Demo

Code zur [Demosession auf der FOSSGIS 2023](https://pretalx.com/fossgis2023/talk/KNLSJN/) von Robert Klemm und Mathias Gröbe

## Inhalt

 - Lua-Skripte zum Import und Reporijzieren der OSM-Daten in eine Datenbank (Zielschema "public", EPGS:23633)
 - Funktionen für die Generalisierung (jeweils mit Verweise auf Quellen)
 - Abfolge von SQL-Befehlen zur Generalisierung (Zielschema "map")

 ## Benötige Software

 - PostgreSQL 13+
 - PostGIS 3+
 - osm2pgsql 1.7+