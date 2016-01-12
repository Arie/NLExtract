.. _bgtextract:


***********
Bgt-extract
***********

Hieronder staat de handleiding voor het gebruik van de tools om BGT te extraheren. Deze tools
heten kortweg ``Bgt-extract`` of soms ``NLExtract-BGT``.

.. NB: als je alleen interesse hebt om een PostGIS versie van de laatste TOP10NL te hebben, kun
   je deze ook downloaden als PostGIS dumpfile via de link http://data.nlextract.nl/top10nl.
   De dump file (``.backup`` bestand)  kun je direct inlezen in PostGIS, bijv met ``PGAdminIII``.
   Dan hoef je alle zaken hieronder niet uit te voeren :-).

Om gespecialiseerde extracties bijv naar andere databases zoals Oracle te doen, neem contact op
met het NLExtract-team, zie "Ondersteuning": http://www.nlextract.nl/issues.

Handleiding BGT-extract
=======================

Algemeen
--------

Bgt-extract is onderdeel van de NLExtract tools voor het inlezen en verrijken van de Basisregistratie Grootschalige Topografie (BGT). Deze open dataset bestaat uit een aantal GML-bestanden en wordt (voorlopig) ingelezen in een PostgreSQL/PostGIS database.

Er zijn 41 typen BGT-objecten (featureklassen). Iedere featureklasse heeft een groot aantal attributen en meestal ook meerdere geometrie-attributen. De BGT is gebaseerd op CityGML. Hierdoor biedt het datamodel ruimte voor toekomstige uitbreiding, bijv. de toevoeging van 3D-geometrie. Zie voor de beschrijving van de structuur en verdere bijzonderheden voor de GML-bestandsindeling de documentatie op `BGTweb <https://bgtweb.pleio.nl/documentatie>`_.

BGT downloaden
--------------

De brondata van de BGT in GML kun je via `PDOK Download Basisregistratie Grootschalige Topografie <https://www.pdok.nl/nl/producten/pdok-downloads/download-basisregistratie-grootschalige-topografie>`_ downloaden.

De BGT wordt via PDOK geleverd in ZIP-bestanden. Het is mogelijk om zowel een landelijk bestand als deelbestanden te downloaden. De laatste zijn opgedeeld in een grid van 2x2, 4x4, 8x8, 16x16, 32x32 en 64x64 km. Het is niet mogelijk om de BGT van een gemeente, provincie of een zelf te definiëren gebied via PDOK te downloaden.

De BGT is beschikbaar in meerdere varianten:

* Met of zonder plaatsbepalingspunten: deze worden door NLExtract ondersteund. Vanwege de omvang van de data wordt sterk aanbevolen om de variant zonder plaatsbepalingspunten te gebruiken.
* GML of GML Light: alleen GML wordt ondersteund.

De BGT bestaat uit zowel een verplicht (BGT) als optioneel (IMGeo) deel. Dit is het zogenaamde "plus"-deel, welke ook door NLExtract wordt ondersteund. Dit laatste bestaat uit nieuwe featureklassen en extra attributen bij bestaande featureklassen.

Momenteel (januari 2016) zijn veel bronhouders bezig om de BGT te vullen. De omvang van het BGT ZIP-bestand van heel Nederland, zonder plaatsbepalingspunten, was op 12 januari jl. 1,91 GB. Voor de kerst, op 21 december jl., was het slechts 1,41 GB. De verwachting is dat het ZIP-bestand van heel Nederland uiteindelijk bijna 50 GB zal zijn. 

Als je heel Nederland wilt inlezen, kun je het beste het bestand exclusief plaatsbepalingspunten, GML-variant, gebruiken. Zie PDOK voor de directe link. Deze verandert namelijk iedere dag.

Bgt-extract downloaden
----------------------

Vind altijd de laatste versie op: http://www.nlextract.nl/file-cabinet (TODO, niet actueel).

Omdat NLExtract voortdurend in ontwikkeling is, kun je ook de actuele broncode, een `snapshot`, downloaden
en op dezelfde manier gebruiken als een versie:

- snapshot via git: git clone http://github.com/opengeogroep/NLExtract.git
- snapshot als .zip: https://github.com/opengeogroep/NLExtract/archive/master.zip

Ontwerp
-------

In eerste instantie wordt de GML geconverteerd en geladen naar PostGIS. Dit gebeurt met de GDAL/OGR tool
ogr2ogr. Echter, het feit dat er meerdere geometrieën per object kunnen voorkomen, maakt dit lastiger. De meeste objecten bevatten zowel een LoD 0-geometrie als een 2D-geometrie. Sommige objecten bevatten tevens een kruinlijn-geometrie. De BGT bevat geen attributen met multipliciteit, d.w.z. meerdere voorkomens van een attribuut.

Om het eerste probleem op te lossen worden middels een XSLT script (etl/xsl/imgeo-split_v2.1.1.xsl) de
GML-elementen uitgesplitst naar geometrie, zodat ieder element een enkele geometrie bevat. Bijvoorbeeld het TrafficArea-element (Wegdeel) wordt opgesplitst naar TrafficArea_2D en TrafficArea_kruinlijn. Vervolgens wordt via ogr2ogr dit uitgesplitste GML bestand in PostGIS geladen. Hierbij vindt ook de uiteindelijke vertaling van de in CityGML gedefinieerde objecten, zoals TrafficArea, naar het Nederlands plaats, zoals Wegdeel.

Zie verder :doc:`stetl-framework` voor de werking van Bgt-extract.
