#!/bin/bash

# kill the script if there are any errors
set -e

# defaults
DEV_DB=robyn_dev
USER=root

DUMP_FILE=$1

# Validate before dropping anything. Without this the drop still runs, and the load
# then sits waiting on stdin — leaving the dev database gone and the script hung.
# The readability check also catches a mistyped path before it costs you the database.
if [ -z "$DUMP_FILE" ]; then
  echo "Usage: $0 <dump-file>" >&2
  exit 1
fi

if [ ! -r "$DUMP_FILE" ]; then
  echo "Error: dump file '$DUMP_FILE' does not exist or is not readable" >&2
  exit 1
fi

# create the daatabase
echo "Rebuilding $DEV_DB from dump"

mysql -u $USER -e "drop database $DEV_DB;"
mysql -u $USER -e "create database $DEV_DB;"


# hydrate the db
echo "Hydrating db $DEV_DB using $DUMP_FILE"
mysql -u $USER $DEV_DB < "$DUMP_FILE"
