## -------------- VARIABLES BLOCK ----------------------
current_date := $(shell date '+%y%m%d')
aws_region := eu-central-1
duckdb_max_memory := 4GB
dbt_max_threads := 6
osmium_pool_threads := 6
max_parallel_workers := 4
DBT_PROFILES_DIR := $(shell pwd)/osmaboar_dbt
export DBT_PROFILES_DIR

## ------------- CONTROL BLOCK -------------------------

clean_all: ## [FINAL] Cleans worktree by removing input data
	rm -rf data/in/osm_data
	rm -f keep_changesets_history_files
	rm -f osmaboardbt.duckdb db/duckdb

clean_dev: ## [FINAL] Cleans data for latest period only
	rm -rf osmaboardbt.duckdb.tmp
	rm -f data/in/osm_data/changesets_latest.osm.bz2 db/dbt_debug db/osm_internal_raw osmaboardbt.duckdb
# 	rm -f data/in/osm_data/poland-latest-internal.osm.pbf

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

db: ## Folder for storing duckdb and dbt related footprints.
	mkdir -p $@

data/in/osm_data/changesets-latest.osm.bz2: | data/in/osm_data ## Download latest planet changeset and rename it to -latest. ~6G
	rm -f data/in/osm_data/changesets-latest.osm.bz2
	cd data/in/osm_data; aria2c --seed-time 0 https://planet.openstreetmap.org/planet/changesets-latest.osm.bz2.torrent 
	rm -f data/in/osm_data/changesets-*.osm.bz2.torrent
	mv data/in/osm_data/changesets-2* data/in/osm_data/changesets-latest.osm.bz2
	touch $@

data/in/osm_data/poland-latest-internal: ## check if internal file exists. Should be downloaded manually. ~2G
	if [ -f data/in/osm_data/poland-latest-internal.osm.pbf ]; then echo "file exists" && touch $@; else echo "file does not exists, please download it" && exit 1; fi

data/mid/osmium: | data/mid ## Folder for temporary osm.bz2 files
	mkdir -p $@

db/poland_internal_raw: data/in/osm_data/poland-latest-internal | db ## Initialize duckdb db and load pbf throug json output to the table. ~20G
	rm -f poland_internal.duckdb
	./duckdb poland_internal.duckdb -c "LOAD shellfs; set memory_limit = '$(duckdb_max_memory)'; create table poland_internal_raw as select json_extract(json, '$.properties') as properties, json_extract(json, '$.geometry') as geom_geojson FROM read_json_objects('OSMIUM_POOL_THREADS=$(osmium_pool_threads) osmium export -i sparse_file_array -c osmium.config.json -f geojsonseq data/in/osm_data/poland-latest-internal.osm.pbf | jq -c |', format='auto');"
	touch $@

data/mid/osmium/changesets-history: data/in/osm_data/changesets-latest.osm.bz2 | data/mid/osmium ## Split changesets data per years, run in parallel. ~7.2G
	if [ -f keep_changesets_history_files ]; then \
		touch $@; else \
		rm -f data/mid/osmium/changesets_2* && \
		cat static_data/changesets_per_yer_division.csv | tail -n +2 | parallel -j $(max_parallel_workers) --colsep ';' 'osmium changeset-filter -a {2} -b {3} --with-changes --closed --fsync data/in/osm_data/changesets-latest.osm.bz2 -o data/mid/osmium/{1}' ; fi
	touch $@

data/mid/osmium/changesets_latest.osm.bz2: data/in/osm_data/changesets-latest.osm.bz2 | data/mid/osmium ## Create changeset file for dates after last historical one
	rm -f $@
	cat static_data/changesets_per_yer_division.csv | tail -1 | parallel -j 1 --colsep ';' 'osmium changeset-filter -a {3} --with-changes --closed --fsync data/in/osm_data/changesets-latest.osm.bz2 -o data/mid/osmium/changesets_latest.osm.bz2'
	touch $@

data/out/parquet: | data/out ## Output folder for parquet files.
	mkdir -p $@

data/out/parquet/changesets-history: data/mid/osmium/changesets-history | data/out/parquet ## Convert historical osm changesets files to parquet ones. ~12G
	rm -f data/out/parquet/changesets_2*.parquet
	cat static_data/changesets_per_yer_division.csv | tail -n +2 | parallel -j $(max_parallel_workers) --colsep ';' 'python scrypts/osm_bz2_to_parquet.py -in data/mid/osmium/{1} -out data/out/parquet/{4} -chunk 5000'
	touch keep_changesets_history_files
	touch $@

data/out/parquet/changesets_latest.parquet: data/mid/osmium/changesets_latest.osm.bz2 | data/out/parquet ## Convert latest osm changesets files to parquet one. ~1.2G
	rm -f $@
	python scrypts/osm_bz2_to_parquet.py -in data/mid/osmium/changesets_latest.osm.bz2 -out data/out/parquet/changesets_latest.parquet -chunk 5000
	touch $@

db/dbt_debug: | db ## check if exit code is 0, clean all.
	cd $(DBT_PROFILES_DIR); dbt clean; dbt debug
	touch $@

db/dbt_models_run: data/out/parquet/changesets-history data/out/parquet/changesets_latest.parquet db/poland_internal_raw db/dbt_debug | db ## Load parquet files into duckdb, create raw and aggregated tables. ~32G after
	rm -f osmaboardbt.duckdb
	rm -rf osmaboardbt.duckdb.tmp
	cd $(DBT_PROFILES_DIR); dbt run --full-refresh
	touch $@

dev: db/dbt_models_run ## [FINAL] final target
	touch $@
