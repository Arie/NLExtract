.. _top10extract:


*************
Top10-extract
*************

Hieronder staat de handleiding voor het gebruik van de tools om Top10NL te extraheren.

Handleiding Top10-extract
=========================

Algemeen
--------

NLExtract/Top10NL, kortweg Top10-extract bevat tools om de Top10NL bronbestanden zoals geleverd door Het Kadaster (GML)
om te zetten naar hanteerbare formaten zoals PostGIS. Tevens bevat Top10-extract visualisatie-bestanden
(onder de map `style/` ) voor QGIS en SLDs om kaarten te maken. (NB deze zijn nu nog gebaseerd op Top10NL 1.0!).

Top10NL (v1.1.1) wordt geleverd door Het Kadaster als een .zip file van plm 2GB. Voor de landsdekkende
versies zijn er 2 soorten .zip-bestanden, een op basis van kaartbladen,
zie `Bestandswijzer_GML_TOP10NL_2012.pdf <https://github.com/opengeogroep/NLExtract/raw/master/top10nl/doc/Bestandswijzer_GML_TOP10NL_2012.pdf>`_
en een .zip file op basis van "GML FileChunks" waarbij de totale GML is opgedeeld in files van 300MB.

Zie verdere bijzonderheden voor de GML bestandsindeling in
`Structuur_GML_TOP10NL_1_1_1.pdf <https://github.com/opengeogroep/NLExtract/raw/master/top10nl/doc/Structuur_GML_TOP10NL_1_1_1.pdf>`_.

Er zijn 14 typen Top10NL objecten. Zie ook de Top10NL structuur-beschrijving in
`Structuur_TOP10NL_1_1_1.pdf <https://github.com/opengeogroep/NLExtract/raw/master/top10nl/doc/Structuur_TOP10NL_1_1_1.pdf>`_.

Top10NL Downloaden
------------------

Uiteraard heb je Top10NL brondata nodig. Deze kun je via http://kadaster.nl/top10nl vinden, maar
we hebben ook een directe download link beschikbaar met dank aan OpenStreetMap-NL, zie:
http://mirror.openstreetmap.nl/kadaster/Top10NL_v1_1_1

`NB  heel belangrijk is om de laatste versie van Top10NL te gebruiken: v1.1.1.` Deze wordt geleverd met ingang van
september 2012. In bijv. PDOK zijn momenteel (okt 2012) nog oudere versies van Top10NL.

Top10-extract downloaden
------------------------

Vind altijd de laatste versie op: http://www.nlextract.nl/file-cabinet

Omdat NLExtract voortdurend in ontwikkeling is kun je ook de actuele broncode, een `snapshot`, downloaden
en op dezelfde manier gebruiken als een versie:

- snapshot via git: git clone http://github.com/opengeogroep/NLExtract.git
- snapshot als .zip: https://github.com/opengeogroep/NLExtract/zipball/master

Ontwerp
-------

In eerste instantie converteren/laden we de GML naar PostGIS. Dit gebeurt met de GDAL/OGR tool
ogr2ogr. Echter er zijn 2 belangrijke zaken die dit lastig maken:

- meerdere geometrie�n per object, bijv een Waterdeel GML element kan een lijn en een vlak bevatten
- meerdere voorkomens van een attribuut (attribute multiplicity), bijv. een Wegdeel GML element kan meerdere element-attributen genaamd "nwegNummer" bevatten

Om het eerste probleem op te lossen worden middels een XSLT script (bin/top10-split.xsl) de GML
elementen uitgesplitst naar geometrie, zodat ieder element een enkele geometrie bevat. Bijvoorbeeld
Wegdeel kent maar liefst 5 geometrie attributen. Dit wordt opgesplitst naar Wegdeel_Lijn, Wegdeel_Vlak etc.
Een nieuw GML bestand wordt hiermee opgebouwd. Vervolgens wordt via ogr2ogr dit uitgesplitste GML bestand
in PostGIS geladen.

NLExtract maakt i.h.a. gebruik van Python voor alle scripts. De Python scripts
voor Top10-extract roepen `native` tools aan:

* XML parsing via `libxml2`
* XSLT processing via `libxslt`
* GDAL/OGR `ogr2ogr`

De reden is vooral snelheid. Top10NL kan niet door `ogr2ogr` direct verwerkt worden.
Met name dienen objecten als `Wegdelen` die meerdere geometrie�n bevatten
uitgesplitst te worden over objecten die een enkele geometrie bevatten, bijv. `Wegdeel_Hartlijn`
en `Wegdeel_Vlak`. Het uitsplitsen gaat met XSLT. De uitgesplitste bestanden worden tijdens
verwerken tijdelijk opgeslagen.

Afhankelijkheden
----------------

De volgende software dient aanwezig te zijn om Top10-extract te draaien.

 - Python 2.6 of hoger (niet Python 3!)
 - Python argparse package, voor argument parsing alleen indien Python < 2.7
 - PostGIS: PostgreSQL database server met PostGIS 1.x en 2.x : http://postgis.refractions.net
 - lxml voor razendsnelle native XML parsing, Zie http://lxml.de/installation.html
 - libxml2 en libxslt bibliotheken  (worden door lxml gebruikt)
 - GDAL/OGR v1.8.1 of hoger (voor ogr2ogr) http://www.gdal.org
 - NB: GDAL/OGR Python bindings zijn (voorlopig) `niet` nodig

Installatie
-----------

Top10-extract werkt op de drie voornaamste platformen: Windows, Mac OSX, Linux.
De bovengenoemde afhankelijkheden hebben ieder hun eigen handleiding voor
installatie op desbetreffend platform. Raadpleeg deze als eerste.
Hieronder een aantal tips en bijzonderheden pet platform.

Linux
~~~~~

Gebruik onder Ubuntu altijd `Ubuntu GIS`: https://wiki.ubuntu.com/UbuntuGIS
om de laatste versies van veel packages, met name GDAL en PostGIS 1.x te verkrijgen!

- optioneel: Python package afhankelijkheden installeren bijv
  ::

   apt-get of yum install python-setuptools (voor easy_install commando)
   apt-get of yum install python-devel (tbv psycopg2 bibliotheek)
   apt-get of yum install postgresql-devel (tbv psycopg2 bibliotheek)

- lxml
  ::

   apt-get of yum install libxml2
   apt-get of yum install libxslt1.1
   apt-get of yum install python-lxml

- GDAL
  ::

   apt-get of yum install gdal-bin

- Python package "argparse" (alleen vor Python < 2.7)
  ::

   sudo easy_install argparse

- NB als je een proxy gebruikt via http_proxy  doe dan easy_install -E (exporteer huidige environment)

Windows
~~~~~~~

De Python scripts zijn ontwikkeld en getest op Windows 7 met Python 2.7.2.

Let op: wanneer je Windows gebruikt en je wilt op de command line met PostgreSQL connecten, gebruik
chcp 1252.

In Python 2.6:

- argparse module: http://pypi.python.org/pypi/argparse
  Het gemakkelijkst is om argparse.py in de directory Python26\Lib\ te droppen

Mac OSX
~~~~~~~

- Python, 2.6.1 of hoger, liefst 2.7+,

- Python package "argparse" (alleen vor Python < 2.7)
  ::

    sudo easy_install argparse

- libxml2 en libxslt: via MacPorts:  http://www.macports.org/

- lxml
  ::

    sudo easy_install lxml

- GDAL: KyngChaos (MacPorts GDAL-versie is vaak outdated) : http://www.kyngchaos.com/software/index Download en install `GDAL Complete`.
  Om te zorgen dat de GDAL commando's, met name `ogr2ogr` kunnen worden gevonden, kun je het volgende
  wijzigen in `/etc/profile`, die standaard Shell settings in het Terminal window bepaalt:
  ::

  export PATH=/Library/Frameworks/GDAL.framework/Versions/Current/Programs:$PATH


Aanroep
-------

De aanroep van Top10-extract is op alle systemen hetzelfde, namelijk via Python ::

    usage: top10extract.py [-h] [--ini SETTINGS_INI] --dir DIR [--pre PRE_SQL]
                        [--post POST_SQL] [--PG_PASSWORD PG_PASS]
                        GML [GML ...]

Verwerk een of meerdere GML-bestanden

positional arguments:
::

  GML                   het GML-bestand of de lijst of directory met GML-bestanden


optional arguments:
::

  -h, --help            show this help message and exit
  --ini SETTINGS_INI    het settings-bestand
  --dir DIR             lokatie getransformeerde bestanden
  --pre PRE_SQL         SQL-script vooraf
  --post POST_SQL       SQL-script achteraf
  --PG_PASSWORD PG_PASS wachtwoord voor PostgreSQL

Het GML-bestand of de GML-bestanden kunnen op meerdere manieren worden meegegeven:

- met 1 GML-bestand
- met bestand met GML-bestanden
- met meerdere GML-bestanden via wildcard
- met directory

NB: ook als er meerdere bestanden via de command line aangegeven kunnen worden, kunnen deze
wildcards bevatten. Een bestand wordt als GML-bestand beschouwd, indien deze de extensie GML of
XML heeft, anders wordt het als een GML-bestandslijst gezien.

Het beste kun je de `TOP10NL_GML_50D_Blokken-` bestanden gebruiken (vanwege mogelijke geheugen-issues).
Na download moet je dus eerst de .zip file uitpakken.

Toepassen settings:

- Definitie in settings-file (top10-settings.ini)
- Mogelijk om settings te overriden via command-line parameters (alleen voor wachtwoorden)
- Mogelijk om settings file mee te geven via command-line

Testen
------
Het beste is eerst je installatie te testen als volgt:

 * pas `bin/top10-settings.ini` aan voor je lokale situatie
 * maak een lege database aan met PostGIS  template bijv. ``top10nl`` (createdb -T postgis)
 * in de ``top10nl/test`` directory executeer ``./top10-test.sh`` of ``./top10-test.cmd``

Valideren
---------

Sommige Top10NL files van Kadaster kunnen soms invalide GML syntax bevatten.
Valideren van een GML bestand (tegen Top10NL 1.1.1 schema) ::

  top10validate.py <Top10NL GML file> - valideer input GML

Top10NL Versies
---------------

Sinds september 2012 is er een nieuwe versie van Top10NL, versie 1.1.1. Gebruik altijd deze. Na NLExtract v1.1.2
zullen we de oude Top10NL versie niet meer ondersteunen.



