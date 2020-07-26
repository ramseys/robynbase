#!/bin/bash

# defaults
DEV_DB=robyn_dev
USER=root

# create the daatabase
echo "Rebuilding $DEV_DB from dump"

mysql -u $USER -e "drop database $DEV_DB;"
mysql -u $USER -e "create database $DEV_DB;"


# hydrate the db
echo "Hydrating backup db $DEV_DB using $1"
mysql -u $USER $DEV_DB < $1