--
-- Maakt en vult afgeleide tabel "adres" aan met volledige adressen
--
-- De BAG bevat geen echte adressen zoals bijv. ACN (Adres Coordinaten Nederland), dwz
-- een tabel met straat, huisnummer, woonplaats, gemeente, provincie etc.
-- De elementen voor een compleet adres zitten wel in de (verrijkte) BAG.
-- Via SQL scripts hieronder wordt een echte "adres" tabel aangemaakt en gevuld
-- uit de BAG basistabellen.
--
-- Auteur: Just van den Broecke
--

-- Maak  een "echte" adressen tabel
DROP TABLE IF EXISTS adres CASCADE;
CREATE TABLE adres (
  openbareruimtenaam character varying(80),
  huisnummer numeric(5,0),
  huisletter character varying(1),
  huisnummertoevoeging character varying(4),
  postcode character varying(6),
  woonplaatsnaam character varying(80),
  gemeentenaam character varying(80),
  provincienaam character varying(16),
  -- 7311SZ 264 len = 178
  verblijfsobjectgebruiksdoel character varying,
  verblijfsobjectstatus character varying,
  typeadresseerbaarobject character varying(3),
  adresseerbaarobject numeric(16,0),
  pandid numeric(16,0),
  pandstatus character varying,
  pandbouwjaar numeric(4,0),
  nummeraanduiding numeric(16,0),
  nevenadres BOOLEAN DEFAULT FALSE,
  geopunt geometry(PointZ, 28992),
  textsearchable_adres tsvector
);

-- Insert (actuele+bestaande) data uit combinatie van BAG tabellen: Verblijfplaats
INSERT INTO adres (openbareruimtenaam, huisnummer, huisletter, huisnummertoevoeging, postcode, woonplaatsnaam, gemeentenaam, provincienaam, verblijfsobjectgebruiksdoel,
                   verblijfsobjectstatus, typeadresseerbaarobject, adresseerbaarobject, pandid, pandstatus, pandbouwjaar, nummeraanduiding, geopunt)
  SELECT
    o.openbareruimtenaam,
    n.huisnummer,
    n.huisletter,
    n.huisnummertoevoeging,
    n.postcode,
    -- Wanneer nummeraanduiding een gerelateerdewoonplaats heeft moet die gebruikt worden ipv via openbareruimte!
    -- Zie issue: https://github.com/nlextract/NLExtract/issues/54
    COALESCE(wp2.woonplaatsnaam,w.woonplaatsnaam),
    COALESCE(p2.gemeentenaam,p.gemeentenaam),
    COALESCE(p2.provincienaam,p.provincienaam),
    ARRAY_TO_STRING(ARRAY_AGG(d.gebruiksdoelverblijfsobject ORDER BY gebruiksdoelverblijfsobject), ', ') AS verblijfsobjectgebruiksdoel,
    v.verblijfsobjectstatus,
    'VBO' as typeadresseerbaarobject,
    v.identificatie as adresseerbaarobject,
    pv.identificatie as pandid,
    pv.pandstatus,
    pv.bouwjaar as pandbouwjaar,
    n.identificatie as nummeraanduiding,
    v.geopunt
  FROM verblijfsobjectactueelbestaand v
    JOIN nummeraanduidingactueelbestaand n
    ON (n.identificatie = v.hoofdadres)
    JOIN verblijfsobjectgebruiksdoelactueelbestaand d
    ON (d.identificatie = v.identificatie)
    LEFT OUTER JOIN verblijfsobjectpandactueel vp
    ON (v.identificatie = vp.identificatie)
    LEFT OUTER JOIN pandactueel pv
    ON (vp.gerelateerdpand = pv.identificatie)
    JOIN openbareruimteactueelbestaand o
    ON (n.gerelateerdeopenbareruimte = o.identificatie)
    JOIN woonplaatsactueelbestaand w
    ON (o.gerelateerdewoonplaats = w.identificatie)
    JOIN gemeente_woonplaatsactueelbestaand  g
    ON (g.woonplaatscode = w.identificatie)
    JOIN provincie_gemeenteactueelbestaand p
    ON (g.gemeentecode = p.gemeentecode)
    -- Wanneer nummeraanduiding een gerelateerdewoonplaats heeft moet die gebruikt worden ipv via openbareruimte!
    -- Zie issue: https://github.com/nlextract/NLExtract/issues/54
    LEFT OUTER JOIN woonplaatsactueelbestaand wp2
    ON (n.gerelateerdewoonplaats = wp2.identificatie)
    LEFT OUTER JOIN gemeente_woonplaatsactueelbestaand  g2
    ON (g2.woonplaatscode = wp2.identificatie)
    LEFT OUTER JOIN provincie_gemeenteactueelbestaand p2
    ON (g2.gemeentecode = p2.gemeentecode)
  GROUP BY
    o.openbareruimtenaam,
    n.huisnummer,
    n.huisletter,
    n.huisnummertoevoeging,
    n.postcode,
    COALESCE(wp2.woonplaatsnaam,w.woonplaatsnaam),
    COALESCE(p2.gemeentenaam,p.gemeentenaam),
    COALESCE(p2.provincienaam,p.provincienaam),
    v.verblijfsobjectstatus,
    typeadresseerbaarobject,
    adresseerbaarobject,
    pandid,
    pv.pandstatus,
    pandbouwjaar,
    nummeraanduiding,
    geopunt;

-- Insert (actuele+bestaande) data uit combinatie van BAG tabellen : Ligplaats
INSERT INTO adres (openbareruimtenaam, huisnummer, huisletter, huisnummertoevoeging, postcode, woonplaatsnaam, gemeentenaam, provincienaam, typeadresseerbaarobject,
                   adresseerbaarobject, pandid, pandstatus, pandbouwjaar, nummeraanduiding, verblijfsobjectgebruiksdoel, verblijfsobjectstatus, geopunt)
  SELECT
    o.openbareruimtenaam,
    n.huisnummer,
    n.huisletter,
    n.huisnummertoevoeging,
    n.postcode,
    -- Wanneer nummeraanduiding een gerelateerdewoonplaats heeft moet die gebruikt worden ipv via openbareruimte!
    -- Zie issue: https://github.com/nlextract/NLExtract/issues/54
    COALESCE(wp2.woonplaatsnaam,w.woonplaatsnaam),
    COALESCE(p2.gemeentenaam,p.gemeentenaam),
    COALESCE(p2.provincienaam,p.provincienaam),
    'LIG' as typeadresseerbaarobject,
    l.identificatie as adresseerbaarobject,
    NULL, -- pandid
    '', -- pandstatus
    NULL, -- pandbouwjaar
    n.identificatie as nummeraanduiding,
    'Ligplaats',
    l.ligplaatsstatus,
    -- Vlak geometrie wordt punt
    ST_Force3D(ST_Centroid(l.geovlak))  as geopunt
  FROM ligplaatsactueelbestaand l
    JOIN nummeraanduidingactueelbestaand n
    ON (n.identificatie = l.hoofdadres)
    JOIN openbareruimteactueelbestaand o
    ON (n.gerelateerdeopenbareruimte = o.identificatie)
    JOIN woonplaatsactueelbestaand w
    ON (o.gerelateerdewoonplaats = w.identificatie)
    JOIN gemeente_woonplaatsactueelbestaand  g
    ON (g.woonplaatscode = w.identificatie)
    JOIN provincie_gemeenteactueelbestaand p
    ON (g.gemeentecode = p.gemeentecode)
    -- Wanneer nummeraanduiding een gerelateerdewoonplaats heeft moet die gebruikt worden ipv via openbareruimte!
    -- Zie issue: https://github.com/nlextract/NLExtract/issues/54
    LEFT OUTER JOIN woonplaatsactueelbestaand wp2
    ON (n.gerelateerdewoonplaats = wp2.identificatie)
    LEFT OUTER JOIN gemeente_woonplaatsactueelbestaand  g2
    ON (g2.woonplaatscode = wp2.identificatie)
    LEFT OUTER JOIN provincie_gemeenteactueelbestaand p2
    ON (g2.gemeentecode = p2.gemeentecode);

-- Insert data uit combinatie van BAG tabellen : Standplaats
INSERT INTO adres (openbareruimtenaam, huisnummer, huisletter, huisnummertoevoeging, postcode, woonplaatsnaam, gemeentenaam, provincienaam, typeadresseerbaarobject,
                   adresseerbaarobject, pandid, pandstatus, pandbouwjaar, nummeraanduiding, verblijfsobjectgebruiksdoel, verblijfsobjectstatus, geopunt)
  SELECT
    o.openbareruimtenaam,
    n.huisnummer,
    n.huisletter,
    n.huisnummertoevoeging,
    n.postcode,
    -- Wanneer nummeraanduiding een gerelateerdewoonplaats heeft moet die gebruikt worden ipv via openbareruimte!
    -- Zie issue: https://github.com/nlextract/NLExtract/issues/54
    COALESCE(wp2.woonplaatsnaam,w.woonplaatsnaam),
    COALESCE(p2.gemeentenaam,p.gemeentenaam),
    COALESCE(p2.provincienaam,p.provincienaam),
    'STA' as typeadresseerbaarobject,
    s.identificatie as adresseerbaarobject,
    NULL, -- pandid
    '', -- pandstatus
    NULL, -- pandbouwjaar
    n.identificatie as nummeraanduiding,
    'Standplaats',
    s.standplaatsstatus,
      -- Vlak geometrie wordt punt
    ST_Force3D(ST_Centroid(s.geovlak)) as geopunt
  FROM standplaatsactueelbestaand s
    JOIN nummeraanduidingactueelbestaand n
    ON (n.identificatie = s.hoofdadres)
    JOIN openbareruimteactueelbestaand o
    ON (n.gerelateerdeopenbareruimte = o.identificatie)
    JOIN woonplaatsactueelbestaand w
    ON (o.gerelateerdewoonplaats = w.identificatie)
    JOIN gemeente_woonplaatsactueelbestaand  g
    ON (g.woonplaatscode = w.identificatie)
    JOIN provincie_gemeenteactueelbestaand p
    ON (g.gemeentecode = p.gemeentecode)
    -- Wanneer nummeraanduiding een gerelateerdewoonplaats heeft moet die gebruikt worden ipv via openbareruimte!
    -- Zie issue: https://github.com/nlextract/NLExtract/issues/54
    LEFT OUTER JOIN woonplaatsactueelbestaand wp2
    ON (n.gerelateerdewoonplaats = wp2.identificatie)
    LEFT OUTER JOIN gemeente_woonplaatsactueelbestaand  g2
    ON (g2.woonplaatscode = wp2.identificatie)
    LEFT OUTER JOIN provincie_gemeenteactueelbestaand p2
    ON (g2.gemeentecode = p2.gemeentecode);

-- NEVENADRESSEN
INSERT INTO adres (openbareruimtenaam, huisnummer, huisletter, huisnummertoevoeging, postcode, woonplaatsnaam, gemeentenaam, provincienaam, typeadresseerbaarobject,
                   adresseerbaarobject, pandid, pandstatus, pandbouwjaar, nummeraanduiding, nevenadres, verblijfsobjectgebruiksdoel, verblijfsobjectstatus, geopunt)
  SELECT
    o.openbareruimtenaam,
    n.huisnummer,
    n.huisletter,
    n.huisnummertoevoeging,
    n.postcode,
    COALESCE(wp2.woonplaatsnaam,w.woonplaatsnaam),
    COALESCE(p2.gemeentenaam,p.gemeentenaam),
    COALESCE(p2.provincienaam,p.provincienaam),
    'VBO' as typeadresseerbaarobject,
    an.identificatie as adresseerbaarobject,
    pv.identificatie as pandid,
    pv.pandstatus,
    pv.bouwjaar as pandbouwjaar,
    n.identificatie as nummeraanduiding,
    TRUE,
    ARRAY_TO_STRING(ARRAY_AGG(d.gebruiksdoelverblijfsobject ORDER BY gebruiksdoelverblijfsobject), ', ') AS verblijfsobjectgebruiksdoel,
    v.verblijfsobjectstatus,
    v.geopunt
  FROM adresseerbaarobjectnevenadresactueel an
    JOIN nummeraanduidingactueelbestaand n
    ON (an.nevenadres = n.identificatie)
    JOIN verblijfsobjectactueelbestaand v
    ON (an.identificatie = v.identificatie)
    LEFT OUTER JOIN verblijfsobjectgebruiksdoelactueel d
    ON (v.identificatie = d.identificatie)
    LEFT OUTER JOIN verblijfsobjectpandactueel vp
    ON (v.identificatie = vp.identificatie)
    LEFT OUTER JOIN pandactueel pv
    ON (vp.gerelateerdpand = pv.identificatie)
    JOIN openbareruimteactueelbestaand o
    ON (n.gerelateerdeopenbareruimte = o.identificatie)
    JOIN woonplaatsactueelbestaand w
    ON (o.gerelateerdewoonplaats = w.identificatie)
    JOIN gemeente_woonplaatsactueelbestaand g
    ON (g.woonplaatscode = w.identificatie)
    JOIN provincie_gemeenteactueelbestaand p
    ON (g.gemeentecode = p.gemeentecode)
    -- Wanneer nummeraanduiding een gerelateerdewoonplaats heeft moet die gebruikt worden ipv via openbareruimte!
    -- Zie issue: https://github.com/nlextract/NLExtract/issues/54
    LEFT OUTER JOIN woonplaatsactueelbestaand wp2
    ON (n.gerelateerdewoonplaats = wp2.identificatie)
    LEFT OUTER JOIN gemeente_woonplaatsactueelbestaand g2
    ON (g2.woonplaatscode = wp2.identificatie)
    LEFT OUTER JOIN provincie_gemeenteactueelbestaand p2
    ON (g2.gemeentecode = p2.gemeentecode)
  GROUP BY
    o.openbareruimtenaam,
    n.huisnummer,
    n.huisletter,
    n.huisnummertoevoeging,
    n.postcode,
    COALESCE(wp2.woonplaatsnaam,w.woonplaatsnaam),
    COALESCE(p2.gemeentenaam,p.gemeentenaam),
    COALESCE(p2.provincienaam,p.provincienaam),
    typeadresseerbaarobject,
    adresseerbaarobject,
    pandid,
    pv.pandstatus,
    pandbouwjaar,
    nummeraanduiding,
    nevenadres,
    v.verblijfsobjectstatus,
    v.geopunt;

INSERT INTO adres (openbareruimtenaam, huisnummer, huisletter, huisnummertoevoeging, postcode, woonplaatsnaam, gemeentenaam, provincienaam, typeadresseerbaarobject,
                   adresseerbaarobject, pandid, pandstatus, pandbouwjaar, nummeraanduiding, nevenadres, verblijfsobjectgebruiksdoel, verblijfsobjectstatus, geopunt)
  SELECT
    o.openbareruimtenaam,
    n.huisnummer,
    n.huisletter,
    n.huisnummertoevoeging,
    n.postcode,
    COALESCE(wp2.woonplaatsnaam,w.woonplaatsnaam),
    COALESCE(p2.gemeentenaam,p.gemeentenaam),
    COALESCE(p2.provincienaam,p.provincienaam),
    'LIG' as typeadresseerbaarobject,
    an.identificatie as adresseerbaarobject,
    NULL, -- pandid
    '', -- pandstatus
    NULL, -- pandbouwjaar
    n.identificatie as nummeraanduiding,
    TRUE,
    'Ligplaats',
    l.ligplaatsstatus,
    ST_Force3D(ST_Centroid(l.geovlak))  as geopunt
  FROM adresseerbaarobjectnevenadresactueel an
    JOIN nummeraanduidingactueelbestaand n
    ON (an.nevenadres = n.identificatie AND n.typeadresseerbaarobject = 'Ligplaats')
    JOIN ligplaatsactueelbestaand l
    ON (an.identificatie = l.identificatie)
    JOIN openbareruimteactueelbestaand o
    ON (n.gerelateerdeopenbareruimte = o.identificatie)
    JOIN woonplaatsactueelbestaand w
    ON (o.gerelateerdewoonplaats = w.identificatie)
    JOIN gemeente_woonplaatsactueelbestaand g
    ON (g.woonplaatscode = w.identificatie)
    JOIN provincie_gemeenteactueelbestaand p
    ON (g.gemeentecode = p.gemeentecode)
    -- Wanneer nummeraanduiding een gerelateerdewoonplaats heeft moet die gebruikt worden ipv via openbareruimte!
    -- Zie issue: https://github.com/nlextract/NLExtract/issues/54
    LEFT OUTER JOIN woonplaatsactueelbestaand wp2
    ON (n.gerelateerdewoonplaats = wp2.identificatie)
    LEFT OUTER JOIN gemeente_woonplaatsactueelbestaand g2
    ON (g2.woonplaatscode = wp2.identificatie)
    LEFT OUTER JOIN provincie_gemeenteactueelbestaand p2
    ON (g2.gemeentecode = p2.gemeentecode);

INSERT INTO adres (openbareruimtenaam, huisnummer, huisletter, huisnummertoevoeging, postcode, woonplaatsnaam, gemeentenaam, provincienaam, typeadresseerbaarobject,
                   adresseerbaarobject, pandid, pandstatus, pandbouwjaar, nummeraanduiding, nevenadres, verblijfsobjectgebruiksdoel, verblijfsobjectstatus, geopunt)
 SELECT
    o.openbareruimtenaam,
    n.huisnummer,
    n.huisletter,
    n.huisnummertoevoeging,
    n.postcode,
    COALESCE(wp2.woonplaatsnaam,w.woonplaatsnaam),
    COALESCE(p2.gemeentenaam,p.gemeentenaam),
    COALESCE(p2.provincienaam,p.provincienaam),
    'STA' as typeadresseerbaarobject,
    an.identificatie as adresseerbaarobject,
    NULL, -- pandid
    '', -- pandstatus
    NULL, -- pandbouwjaar
    n.identificatie as nummeraanduiding,
    TRUE,
    'Standplaats',
    s.standplaatsstatus,
    ST_Force3D(ST_Centroid(s.geovlak)) as geopunt
  FROM adresseerbaarobjectnevenadresactueel an
    JOIN nummeraanduidingactueelbestaand n
    ON (an.nevenadres = n.identificatie AND n.typeadresseerbaarobject = 'Standplaats')
    JOIN standplaatsactueelbestaand s
    ON (an.identificatie = s.identificatie)
    JOIN openbareruimteactueelbestaand o
    ON (n.gerelateerdeopenbareruimte = o.identificatie)
    JOIN woonplaatsactueelbestaand w
    ON (o.gerelateerdewoonplaats = w.identificatie)
    JOIN gemeente_woonplaatsactueelbestaand g
    ON (g.woonplaatscode = w.identificatie)
    JOIN provincie_gemeenteactueelbestaand p
    ON (g.gemeentecode = p.gemeentecode)
    -- Wanneer nummeraanduiding een gerelateerdewoonplaats heeft moet die gebruikt worden ipv via openbareruimte!
    -- Zie issue: https://github.com/nlextract/NLExtract/issues/54
    LEFT OUTER JOIN woonplaatsactueelbestaand wp2
    ON (n.gerelateerdewoonplaats = wp2.identificatie)
    LEFT OUTER JOIN gemeente_woonplaatsactueelbestaand g2
    ON (g2.woonplaatscode = wp2.identificatie)
    LEFT OUTER JOIN provincie_gemeenteactueelbestaand p2
    ON (g2.gemeentecode = p2.gemeentecode);
-- EINDE NEVENADRESSEN

-- Vul de text vector kolom voor full text search
UPDATE adres set textsearchable_adres = to_tsvector(openbareruimtenaam||' '||huisnummer||' '||trim(coalesce(huisletter,'')||' '||coalesce(huisnummertoevoeging,''))||' '||woonplaatsnaam);

-- Maak indexen aan na inserten (betere performance)
CREATE INDEX adres_geom_idx ON adres USING gist (geopunt);
CREATE INDEX adres_adreseerbaarobject ON adres USING btree (adresseerbaarobject);
CREATE INDEX adres_nummeraanduiding ON adres USING btree (nummeraanduiding);
CREATE INDEX adresvol_idx ON adres USING gin (textsearchable_adres);

-- Populeert public.geometry_columns
-- Dummy voor PostGIS 2+
SELECT public.probe_geometry_columns();

DROP SEQUENCE IF EXISTS adres_gid_seq;
CREATE SEQUENCE adres_gid_seq;
ALTER TABLE adres ADD gid integer UNIQUE;
ALTER TABLE adres ALTER COLUMN gid SET DEFAULT NEXTVAL('adres_gid_seq');
UPDATE adres SET gid = NEXTVAL('adres_gid_seq');
ALTER TABLE adres ADD PRIMARY KEY (gid);
