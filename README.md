# osmaboardbt project description

Straightforward project to consume OSM data, DuckDB and DBT for data transformation to analize metadata.
Puts result to S3-comptable storage to be shown in some dashboard.

## Pipeline Steps Overview

1. Download full changesets history file from planet OSM
2. Download osm pbf file(s) for country of interest (Poland, for example)
3. Split changesets history to smaller osm.bz2 files
4. Transform changesets files to parquet ones
5. Load into local DuckDB and apply transformations via dbt models
6. Perform analyzis
7. Load regular OSM data for more analyzis
8. ....
9. PROFIT!!

## Project overview

The project framework is based on [geocint-runner](https://github.com/konturio/geocint-runner) - geodata
ETL/CI/CD pipeline:

- GNU Make is used as job server
- [make-profiler](https://github.com/konturio/make-profiler) is used as linter and preprocessor for Make
- GNU Parallel is used for paralleling tasks
- osmium-tool and other classical GIS tools are used

Core differences:

- DuckDB + quackosm is used instead of PostgreSQL + Postgis
- Db data transformations is managed by dbt

## Dependencies installation

To be updated!

- sudo apt-get install parallel
- pip install aria2

### DuckDB, dbt

Please follow official documentation

- pip install duckdb --upgrade
- pip install quackosm
- pip install quackosm[cli]
- pip install dbt-core dbt-duckdb

## Current state

Step 5 from Steps Overview is in progress, parquet files preparation is ready:

```SQL
D select filename, count(*) cnt from read_parquet('data/out/parquet/changesets_*.parquet', filename = true) group by 1 order by 1;

┌───────────────────────────────────────────────┬──────────┐
│                   filename                    │   cnt    │
│                    varchar                    │  int64   │
├───────────────────────────────────────────────┼──────────┤
│ data/out/parquet/changesets_2005_2012.parquet │ 18938166 │
│ data/out/parquet/changesets_2013_2015.parquet │ 20731429 │
│ data/out/parquet/changesets_2016.parquet      │  8420095 │
│ data/out/parquet/changesets_2017.parquet      │ 10091179 │
│ data/out/parquet/changesets_2018.parquet      │ 10756788 │
│ data/out/parquet/changesets_2019.parquet      │ 13068229 │
│ data/out/parquet/changesets_2020.parquet      │ 17588235 │
│ data/out/parquet/changesets_2021.parquet      │ 18808719 │
│ data/out/parquet/changesets_2022.parquet      │ 15036354 │
│ data/out/parquet/changesets_2023.parquet      │ 14889321 │
│ data/out/parquet/changesets_2024.parquet      │ 12973297 │
├───────────────────────────────────────────────┴──────────┤
│ 11 rows                                        2 columns │
└──────────────────────────────────────────────────────────┘
Run Time (s): real 3.592 user 7.167735 sys 1.145013
```
