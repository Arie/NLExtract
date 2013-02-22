#!/bin/sh
#
# Auteur: Just van den Broecke
# Test script
#
TOP10NL_HOME=`dirname $0`/../..
TOP10NL_HOME=`(cd "$TOP10NL_HOME"; pwd)`
TOP10NL_BIN=$TOP10NL_HOME/bin
TOP10NL_TEST_DATA=$TOP10NL_HOME/test/1.0/data
TOP10NL_TEST_TMP=$TOP10NL_HOME/test/1.0/tmp

# Temp dir voor gesplitste GML files and .gfs bestanden
/bin/rm -rf $TOP10NL_TEST_TMP
mkdir $TOP10NL_TEST_TMP

python $TOP10NL_BIN/top10extract.py $TOP10NL_TEST_DATA/test.gml --dir $TOP10NL_TEST_TMP

