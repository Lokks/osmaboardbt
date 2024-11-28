## -------------- VARIABLES BLOCK ----------------------
current_date := $(shell date '+%y%m%d')
aws_region := eu-central-1
dbt_max_memory := 4096
dbt_max_threads := 6
max_parallel_workers := 4
DBT_PROFILES_DIR := $(shell pwd)/osmaboar_dbt
export DBT_PROFILES_DIR

## ------------- CONTROL BLOCK -------------------------

clean_all: ## [FINAL] Cleans worktree by removing input data
	rm -rf data/in/osm_data

clean_dev: ## [FINAL] Cleans data for latest period only
	rm -rf data/in/osm_data/changesets_latest.osm.bz2
	rm -rf data/in/osm_data/poland-latest.osm.pbf
	rm -f db/dbt/debug

data: ## file based datasets.
	mkdir -p $@

data/in: | data  ## Input data.
	mkdir -p $@	

data/mid: | data  ## Intermediate data.
	mkdir -p $@

data/out: | data ## Generated final data.
	mkdir -p $@

data/in/osm_data: | data/in ## Data from OSM resources.
	mkdir -p $@

data/in/osm_data/changesets_latest.osm.bz2: | data/in/osm_data ## Download latest planet changeset and rename it to -latest
	rm -f data/in/osm_data/changesets_latest.osm.bz2
	cd data/in/osm_data; aria2c --seed-time 0 https://planet.openstreetmap.org/planet/changesets-latest.osm.bz2.torrent 
	rm -f data/in/osm_data/changesets-*.osm.bz2.torrent
	mv changesets-2* changesets_latest.osm.bz2
	touch $@

# data/in/osm_data/poland-latest.osm.pbf: | data/in/osm_data ## Download latest Poland osm data
# 	rm -f data/in/osm_data/poland-latest.osm.pbf
# 	wget "https://download.geofabrik.de/europe/poland-latest.osm.pbf" -q -O $@

data/mid/osmium: | data/mid ## Folder for temporary osm.bz2 files
	mkdir -p $@

data/mid/osmium/changesets-history: | data/in/osm_data/changesets_latest.osm.bz2 data/mid/osmium ## Ssplit changesets data per years, run in parallel
	rm -f data/mid/osmium/changesets_2*
	cat static_data/changesets_per_yer_division.csv | tail -n +2 | parallel -j $(max_parallel_workers) --colsep ';' 'osmium changeset-filter -a {2} -b {3} --with-changes --closed --fsync data/in/osm_data/changesets_latest.osm.bz2 -o data/mid/osmium/{1}'	
	touch $@

data/mid/osmium/changesets_latest.osm.bz2: data/in/osm_data/changesets_latest.osm.bz2 | data/mid/osmium ## Create changeset file for dates after last historical one
	rm -f $@
	cat static_data/changesets_per_yer_division.csv | tail -1 | parallel -j 1 --colsep ';' 'osmium changeset-filter -a {3} --with-changes --closed --fsync data/in/osm_data/changesets_latest.osm.bz2 -o data/mid/osmium/changesets_latest.osm.bz2'
	touch $@

data/out/parquet: | data/out ## Output folder for parquet files.
	mkdir -p $@

data/out/parquet/changesets-history: data/mid/osmium/changesets-history | data/out/parquet ## Convert historical osm changesets files to parquet ones
	rm -f data/out/parquet/changesets_2*.parquet
	cat static_data/changesets_per_yer_division.csv | tail -n +2 | parallel -j $(max_parallel_workers) --colsep ';' 'python scrypts/osm_bz2_to_parquet.py -in data/mid/osmium/{1} -out data/out/parquet/{4} -chunk 5000'
	touch $@

#data/out/parquet/changesets_latest.parquet: data/mid/osmium/changesets_latest.osm.bz2 | data/out/parquet ## Convert latest osm changesets files to parquet one
#	rm -f $@
#	python scrypts/osm_bz2_to_parquet.py -in data/mid/osmium/changesets_latest.osm.bz2 -out data/out/parquet/changesets_latest.parquet -chunk 5000
#	touch $@

data/out/parquet/changesets_latest.parquet: data/out/parquet/changesets-history | data/out/parquet ## test runs with test files
	rm -f $@
	mv data/out/parquet/changesets_2024.parquet data/out/parquet/changesets_latest.parquet
	touch $@

db: ## Folder for storing duckdb and dbt related footprints.
	mkdir -p $@

db/dbt: | db ## Folder for storing dbt actions footprints.
	mkdir -p $@

db/dbt/debug: | db/dbt ## check if exit code is 0, clean all
	cd $(DBT_PROFILES_DIR); dbt clean; dbt debug
	touch $@

db/dbt/models_created: data/out/parquet/changesets-history data/out/parquet/changesets_latest.parquet db/dbt/debug | db/dbt ## Load parquet files into duckdb, create raw and aggregated tables.
	cd $(DBT_PROFILES_DIR); dbt run --full-refresh
	touch $@

dev: db/dbt/models_created data/out/parquet/changesets_latest.parquet ## [FINAL] final target
	touch $@
