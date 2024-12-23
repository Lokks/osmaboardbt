# osmaboardbt project description

Straightforward project to consume OSM data, DuckDB and DBT for data transformation to analize metadata.
Puts result to S3 public storage to be used in some dashboards/warehouses.
Data management approach is not consistent due to the main purpose - testing tools.

## Pipeline Steps Overview

1. Download full changesets history file from planet OSM
2. Download internal(!) osm pbf file(s) for country of interest (Poland, for example)
3. Split changesets history to smaller osm.bz2 files
4. Transform changesets files to parquet ones
5. Load parquet into local DuckDB and apply transformations via dbt models
6. Perform analyzis
7. Load regular OSM data for more analyzis
8. Put results to public S3 storage
9. Make some visualizations
10. ....
11. PROFIT!!

## Project overview

The project framework is based on [geocint-runner](https://github.com/konturio/geocint-runner) - geodata
ETL/CI/CD pipeline:

- GNU Make is used as job server
- [make-profiler](https://github.com/konturio/make-profiler) is used as linter and preprocessor for Make
- GNU Parallel is used for paralleling tasks
- osmium-tool and other classical GIS tools are used

Core differences:

- DuckDB + quackosm is used instead of PostgreSQL + Postgis
- Db data transformations (at least final ones) are managed by dbt

## Disk usage

Make sure you have around 75G disk space free for it's current state.
Some estimates might be foud in targets comments.

## Dependencies installation

To be updated!

- sudo apt-get install parallel
- pip install aria2

### DuckDB, dbt

Please follow official documentation

- pip install duckdb --upgrade
- pip install quackosm ## (with spatial, json and shellfs extensions)
- pip install quackosm[cli]
- pip install dbt-core dbt-duckdb

## Current state

Step 1-8 from Steps Overview done (in some way).
Parquet files preparation is ready:

```SQL
D select filename, count(*) cnt from read_parquet('data/out/parquet/changesets_*.parquet', filename = true) group by 1 order by 1;

┌───────────────────────────────────────────────┬──────────┐
│                   filename                    │   cnt    │
│                    varchar                    │  int64   │
├───────────────────────────────────────────────┼──────────┤
│ data/out/parquet/changesets_2005_2012.parquet │ 13777528 │
│ data/out/parquet/changesets_2013_2015.parquet │ 20731429 │
│ data/out/parquet/changesets_2016.parquet      │  8420095 │
│ data/out/parquet/changesets_2017.parquet      │ 10091179 │
│ data/out/parquet/changesets_2018.parquet      │ 10756788 │
│ data/out/parquet/changesets_2019.parquet      │ 13068229 │
│ data/out/parquet/changesets_2020.parquet      │ 17588235 │
│ data/out/parquet/changesets_2021.parquet      │ 18808719 │
│ data/out/parquet/changesets_2022.parquet      │ 15036354 │
│ data/out/parquet/changesets_2023.parquet      │ 14889321 │
│ data/out/parquet/changesets_2024.parquet      │ 12775670 │
│ data/out/parquet/changesets_latest.parquet    │   659191 │
├───────────────────────────────────────────────┴──────────┤
│ 12 rows                                        2 columns │
└──────────────────────────────────────────────────────────┘

```

Even test dashboard is available in [public notebook](https://databricks-prod-cloudfront.cloud.databricks.com/public/4027ec902e239c93eaaa8714f173bcfc/1763064240701749/2736829745881847/2628409179466692/latest.html) !
