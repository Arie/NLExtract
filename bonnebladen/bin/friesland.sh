
# Test: converteer files voor frieslan
./bonnetrans.sh b074-1931.png
./bonnetrans.sh b075-1930.png
./bonnetrans.sh b091-1932.png
./bonnetrans.sh b092-1928.png

SETTINGS_SCRIPT="settings.sh"
. $SETTINGS_SCRIPT
mv ${BONNE_DATA_DST_DIR}/b074-1931.tif ${BONNE_DATA_HOME}/friesland-trans
mv ${BONNE_DATA_DST_DIR}/b075-1930.tif ${BONNE_DATA_HOME}/friesland-trans
mv ${BONNE_DATA_DST_DIR}/b091-1932.tif ${BONNE_DATA_HOME}/friesland-trans
mv ${BONNE_DATA_DST_DIR}/b092-1928.tif ${BONNE_DATA_HOME}/friesland-trans

echo "Maak index.shp aan met gdaltindex in ${BONNE_DATA_HOME}/friesland-trans"
pushd ${BONNE_DATA_HOME}/friesland-trans
gdaltindex index.shp *.tif
popd

