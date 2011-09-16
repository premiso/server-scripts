#!/bin/bash
#
# The purpose of this script is to restore a backed up sql / gzipped database. 
# The backup file names should be in the form of database.tablename.sql.gz 
#  Later I may support a wider variety of names, for now this will do.
#  You need to edit the script with your database password and databases to restore
#  
#
MYSQL_USER="user"
MYSQL_PASS="pass"

# A path either needs to be set or this script needs to be ran from the directory.
PATH=/path/to/database/files

DATABASES[0]="db1"
DATABASES[1]="db2"

for db in "${DATABASES[@]}"
do
	for a in $PATH/$db*.gz; 
	do 
		echo "Restoring $a"
		gunzip < $a | mysql -u $MYSQL_USER -p$MYSQL_PASS $db; 
		echo "Done processing $a \n"
	done
done
