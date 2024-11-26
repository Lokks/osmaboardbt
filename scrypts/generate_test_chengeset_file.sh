#!/bin/bash

# This script generates test (dev, filtered) version of changesets-latest.osm.bz2 file.
# Useful for test runs not to wait several hours to process everythingall the data
# Contains changesets made in October for several years.
# Ideally logic should match (at) with ../static_data/changesets_per_year_division.csv
# Requeres latest changesets file in ../data/in/osm_data/changesets-latest.osm.bz2 file (see Makefile).
# Number of job workers (except when it's 1) might be adjusted for your hardware.

#mkdir -p ../data/test
#rm -f ../data/test/*
#cat ../static_data/changesets_per_yer_test_dataset.csv | tail -n +2 | parallel -j 6 --colsep ';' 'osmium changeset-filter -a {2} -b {3} --with-changes --closed --fsync ../data/in/osm_data/changesets-latest.osm.bz2 -o ../data/test/{1}'

cat ../static_data/changesets_per_yer_test_dataset.csv | tail -n +2 | head -1    | parallel -j 1 --colsep ';' 'bzcat ../data/test/{1} | head -n -1 > ../data/test/test-changesets-latest.osm'
cat ../static_data/changesets_per_yer_test_dataset.csv | tail -n +3 | head -n -1 | parallel -j 1 --colsep ';' 'bzcat ../data/test/{1} | head -n -1 | tail -n +3 >> ../data/test/test-changesets-latest.osm'
cat ../static_data/changesets_per_yer_test_dataset.csv | tail -1    | head -1    | parallel -j 1 --colsep ';' 'bzcat ../data/test/{1} | tail -n +3 >> ../data/test/test-changesets-latest.osm'
bzip2 ../data/test/test-changesets-latest.osm
# rm -f ../data/test/test-changesets-latest.osm