## -------------- EXPORT BLOCK ------------------------
current_date:=$(shell date '+%y%m%d')
aws_region:= eu-central-1
max_parallel_workers:= 4
export DBT_PROFILES_DIR=$(pwd)/osmaboar_dbt/

## ------------- CONTROL BLOCK -------------------------

dev: pg_db/table/osm_pl data/in/osm_data/changesets-latest.osm.bz2 ## [FINAL] send data to cloud storage
	touch $@

clean_all: ## [FINAL] Cleans worktree by removing input data
	rm -rf data/in/osm_data

clean_dev: ## [FINAL] Cleans data for latest period only
	rm -rf data/in/osm_data/changesets-latest.osm.bz2
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

data/in/osm_data: | data/in ## Data downloaded within project Global Fires.
	mkdir -p $@

data/in/osm_data/changesets-latest.osm.bz2: | data/in/osm_data ## Download latest planet changeset and renami it to -latest
	rm -f data/in/osm_data/changesets-latest.osm.bz2
	cd data/in/osm_data; aria2c --seed-time 0 https://planet.openstreetmap.org/planet/changesets-latest.osm.bz2.torrent 
	rm -f data/in/osm_data/changesets-*.osm.bz2.torrent
	mv changesets-2* changesets-latest.osm.bz2
	touch $@

# data/in/osm_data/poland-latest.osm.pbf: | data/in/osm_data ## Download latest Poland osm data
# 	rm -f data/in/osm_data/poland-latest.osm.pbf
# 	wget "https://download.geofabrik.de/europe/poland-latest.osm.pbf" -q -O $@

data/mid/osmium: | data/mid ## create folder for temp files to be loaded into PG
	mkdir -p $@

data/mid/osmium/changesets-history: | data/in/osm_data/changesets-latest.osm.bz2 data/mid/osmium ## split changeset data per years, run in parallel
	rm -f data/mid/osmium/changesets_2*
	cat static_data/changesets_per_yer_division.csv | tail -n +2 | parallel -j $(max_parallel_workers) --colsep ';' 'osmium changeset-filter -a {2} -b {3} --with-changes --closed --fsync data/in/osm_data/changesets-latest.osm.bz2 -o data/mid/osmium/{1}'	
	touch $@

data/mid/osmium/changesets-latest.osm.bz2: data/in/osm_data/changesets-latest.osm.bz2 | data/mid/osmium ## create changeset file for dates after last historical one
	rm -f $@
	cat static_data/changesets_per_yer_division.csv | tail -1 | parallel -j 1 --colsep ';' 'osmium changeset-filter -a {3} --with-changes --closed --fsync data/in/osm_data/changesets-latest.osm.bz2 -o data/mid/osmium/changesets-latest.osm.bz2'
	touch $@

data/out/parquet: | data/out ## output folder for parquet files.
	mkdir -p $@

data/out/parquet/changesets-latest.parquet: data/mid/osmium/changesets-latest.osm.bz2 | data/out/parquet ## convert latest osm changesets files to parquet one
	rm -f $@
	python scrypts/osm_bz2_to_parquet.py  -in data/mid/osmium/changesets-latest.osm.bz2  -out data/out/parquet/changesets-latest.parquet -chunk 5000
	touch $@

data/out/parquet/changesets-history: data/mid/osmium/changesets-history | data/out/parquet ## convert historical osm changesets files to parquet ones
	rm -f data/out/parquet/changesets_2*.parquet
	cat static_data/changesets_per_yer_division.csv | tail -n +2 | parallel -j $(max_parallel_workers) --colsep ';' 'python scrypts/osm_bz2_to_parquet.py  -in data/mid/osmium/{1}  -out data/out/parquet/{4} -chunk 5000'
	touch $@

db: ## Directory for storing duckdb and dbt related footprints.
	mkdir -p $@

db/dbt: | db ## Directory for storing dbt actions footprints.
	mkdir -p $@

db/dbt/debug: | db/dbt ## check if exit code is 0
	export DBT_PROFILES_DIR=$(pwd)/osmaboar_dbt/
	cd $(DBT_PROFILES_DIR); dbt clean; dbt debug
	touch $@

db/dbt/models_created: data/out/parquet/changesets-history db/dbt/debug | db/dbt ## Load parquet files into duckdb, create raw and aggregated tables.
	export DBT_PROFILES_DIR=$(pwd)/osmaboar_dbt/
	cd $(DBT_PROFILES_DIR); dbt run --full-refresh
	touch $@

dev: db/dbt/models_created data/out/parquet/changesets-latest.parquet ## [FINAL] final target
	touch $@
