-- Auteur: Frank Steggink
-- Doel: script om TOP1000NL tabellen te verwijderen.
-- Zowel de originele als de opgesplitste tabellen worden hiermee verwijderd.

SET search_path={schema},public;

DROP TABLE IF EXISTS	functioneelgebied;
DROP TABLE IF EXISTS	functioneelgebied_punt;
DROP TABLE IF EXISTS	functioneelgebied_vlak;
DROP TABLE IF EXISTS	functioneelgebied_tmp;

DROP TABLE IF EXISTS	gebouw;
DROP TABLE IF EXISTS	gebouw_punt;
DROP TABLE IF EXISTS	gebouw_tmp;

DROP TABLE IF EXISTS	geografischgebied;
DROP TABLE IF EXISTS	geografischgebied_punt;
DROP TABLE IF EXISTS	geografischgebied_vlak;
DROP TABLE IF EXISTS	geografischgebied_tmp;

DROP TABLE IF EXISTS	hoogte;
DROP TABLE IF EXISTS	hoogte_lijn;
DROP TABLE IF EXISTS	hoogte_punt;
DROP TABLE IF EXISTS	hoogte_tmp;

DROP TABLE IF EXISTS	inrichtingselement;
DROP TABLE IF EXISTS	inrichtingselement_lijn;
DROP TABLE IF EXISTS	inrichtingselement_punt;
DROP TABLE IF EXISTS	inrichtingselement_tmp;

DROP TABLE IF EXISTS	plaats;
DROP TABLE IF EXISTS	plaats_punt;
DROP TABLE IF EXISTS	plaats_vlak;
DROP TABLE IF EXISTS	plaats_tmp;

DROP TABLE IF EXISTS	plantopografie;
DROP TABLE IF EXISTS	plantopografie_lijn;
DROP TABLE IF EXISTS	plantopografie_punt;
DROP TABLE IF EXISTS	plantopografie_vlak;
DROP TABLE IF EXISTS	plantopografie_tmp;

DROP TABLE IF EXISTS	registratiefgebied;
DROP TABLE IF EXISTS	registratiefgebied_vlak;
DROP TABLE IF EXISTS	registratiefgebied_tmp;

DROP TABLE IF EXISTS	spoorbaandeel;
DROP TABLE IF EXISTS	spoorbaandeel_lijn;
DROP TABLE IF EXISTS	spoorbaandeel_tmp;

DROP TABLE IF EXISTS	terrein;
DROP TABLE IF EXISTS	terrein_vlak;
DROP TABLE IF EXISTS	terrein_tmp;

DROP TABLE IF EXISTS	waterdeel;
DROP TABLE IF EXISTS	waterdeel_lijn;
DROP TABLE IF EXISTS	waterdeel_vlak;
DROP TABLE IF EXISTS	waterdeel_tmp;

DROP TABLE IF EXISTS	wegdeel;
DROP TABLE IF EXISTS	wegdeel_lijn;
DROP TABLE IF EXISTS	wegdeel_punt;
DROP TABLE IF EXISTS	wegdeel_tmp;

SET search_path="$user",public;
