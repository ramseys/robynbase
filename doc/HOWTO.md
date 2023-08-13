# HOWTO

## How to Restore the Robynbase DB locally

This command restores the dev database using the given SQL dump.

The dev database is dropped and recreated, so make sure the dump also recreates the schema.

```
./utilities/restore_dev_from_dump.sh <MYSQL dump file>
```

Note: if this is production dump, you need to remove the CREATE DATABASE statement at the beginning

## Create backup of local db

This command writes a backup of the dev database (robyn_dev) to a backup database (robyn_dev_backup), which it creates from scratch.

```
./utilities/create_backup.sh 
```

## Import a venue location CSV file

Imports location information from a CSV file:

1. Subcity
2. Street Address (1 and 2)
3. Latitude
4. Longitude 

It'll ignore rows that don't have a longitude/latitude.

The command below must be run from the `imports` directory.

```
RAILS_ENV=development ruby import_venue_locations.rb <CSV FILE> [--csv <CSV DUMP DIRECTORY>] [-p]
```

## Import a CSV file

This **must** be run from the `./import` directory 

```
RAILS_ENV=development ruby read_import_csv.rb <CSV file>
```
