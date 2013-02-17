#!/bin/bash
#
# Transformeer enkel Bonneblad van bron (PNG) naar GeoTiff.
#
# Auteur: Just van den Broecke
# Frank Steggink: ImageMagick rotatie commandline
#
# Aanroep:
# bonnetrans.sh <bonneblad bronfile naam>
# voorbeeld:
# bonnetrans.sh b027-1932.png


# In de settings file per host, staat de locatie van de bron
# .png van de Bonnebladen
SETTINGS_SCRIPT="settings.sh"
. $SETTINGS_SCRIPT
SETTINGS_SCRIPT="settings-`hostname`.sh"
. $SETTINGS_SCRIPT

fileName=$1

# Compleet pad naar bron bestand
src=${BONNE_DATA_SRC_DIR}/${fileName}

# Extraheer bladnummer, jaar en basis-filenaam
bladnr=`echo $fileName | cut -d'b' -f2 | cut -d'-' -f1`
jaar=`echo $fileName | cut -d'-' -f2 | cut -d'.' -f1`
srcname=`echo $fileName | cut -d'.' -f1`

# Haal de georeferentie coordinaten uit de .csv
line=`grep "^[ ]*${bladnr}" bonnecoords.csv`
# echo $line

nwx=`echo $line | cut -d' ' -f2`
nwy=`echo $line | cut -d' ' -f3`
nex=`echo $line | cut -d' ' -f4`
ney=`echo $line | cut -d' ' -f5`
swx=`echo $line | cut -d' ' -f6`
swy=`echo $line | cut -d' ' -f7`
sex=`echo $line | cut -d' ' -f8`
sey=`echo $line | cut -d' ' -f9`

dsttmp=${BONNE_DATA_DST_DIR}/${srcname}.tmp.tif
dst=${BONNE_DATA_DST_DIR}/${srcname}.tif


# create fully referenced geotiff van bron PNG
# $1 : bron PNG
# $2 temp bestand
# $3 doel bestand GeoTIFF
function createGeoTiff() {
	src_png=$1
	dst_tif=$2
	tmp_tif=${dst_tif}.tmp.tif
 	tmp_png=${src_png}.tmp.png
    nw="$swx $nwy"
    se="$nex $sey"

    if [ -z "$swx" ] || [ -z "$nwy" ] || [ -z "$nex" ] || [ -z "$sey" ]
    then
        echo "$srcname : coords EMPTY - NOT processing"
        return 0
    fi

    echo "START CONVERT $srcname : nw=[$nw] se=[$se]"

    # Roteren: laat zwarte randen verdwijnen (met dank aan Frank Steggink)
    # -define +dither -map $src_png is om colormap te behouden (anders wordt ie RGB en bestand 3x groter)
    convert $src_png -set tiff:software "NLExtract" -set tiff:timestamp "`date`" -brightness-contrast ${BRIGHTNESS_CONTRAST} -affine ${AFFINE} -transform -crop ${CROP} -define +dither -map $src_png $tmp_png

    # Maak GeoTIFF van PNG met juiste georeferentie
    gdal_translate -of GTiff -a_ullr $nw $se -co TILED=YES -a_srs EPSG:28992 $tmp_png $dst_tif

    # Maak overview (pyramid)
    gdaladdo -r average $dst_tif  ${GDAL_OVERVIEW_LEVELS}

	/bin/rm $tmp_png
    echo "END CONVERT $srcname"
}

if [ -e $src ]
then
    createGeoTiff $src $dst
fi









