# FOSSGIS2023 PostGIS Generalisierungs Demo

Code zur [Demosession auf der FOSSGIS 2023](https://pretalx.com/fossgis2023/talk/KNLSJN/) von Robert Klemm und Mathias Gröbe

## Inhalt

 - Lua-Skripte zum Import und Reporijzieren der OSM-Daten in eine Datenbank (Zielschema "public", EPGS:23633)
 - Funktionen für die Generalisierung (jeweils mit Verweise auf Quellen)
 - Abfolge von SQL-Befehlen zur Generalisierung von Wald und Gebäuden (Schema "map")
 - Beispiel für Verdrängung von Punkten und Linien (Schema "displacement")

## Beispiele 

Für vier verschiedene Beispile sind Mögllichkeiten zur Generalisierung aufgezeigt, welche mittels PostGIS Funktionen in PostgreSQL implementiert wurden. Die Lösungen sind jeweils auf vergleichbare Objektklassen übertragbar und sollten an den jeweiligen Zielmaßstab angepasst werden. Wie man die Werte dafür ermittelt wird [hier](https://pretalx.com/fossgis2021/talk/38SRQD/) zum Beispiel erklärt. Weitere Beispiele sind ebenfalls [hier](https://github.com/MathiasGroebe/FOSSGIS2022-PostGIS-Generalisierungs-Demo) verfügbar.
### Vereinfachung von Wald mittels Puffern

![Beispiel Gebäude](img/beispiel_wald.png)

### Vereinfachung von Gebäuden mittels Puffern

![Beispiel Gebäude](img/beispiel_geb%C3%A4ude.png)

### Verdrängung von Wegweisern durch Straßen und Wege

### Verdrängung von Strommasten durch Straßen

## Benötige Software

 - PostgreSQL 13+
 - PostGIS 3+
 - osm2pgsql 1.7+