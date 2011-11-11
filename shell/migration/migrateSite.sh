#!/bin/bash
#
#  Attempt to migrate site from Server A to Server B
#	Requires SSH-Key installed for Server A on Server B
#
#

# @todo: Setup the if statement for command line arguments.
siteName='blogusage.com' # @ todo get this from cli args
pullSQL=true
phpFPMConnections=5
remoteDBUsername='migtest'
remoteDBPassword='migtest'
localDBUsername=''
localDBPassword=''
hasSSL=false

mysqlDumpQuery="mysqldump --compact --add-drop-database --add-drop-table --extended-insert --skip-comments -Q -u${remoteDBUsername} -p${remoteDBPassword} "

#@todo have to figure out how to connect to get a database dump...command over ssh?
userDatabases=($(mysql -u${remoteDBUsername} -p${remoteDBPassword} <<QUERY_INPUT
select schema_name from information_schema.schemata WHERE schema_name NOT IN ('information_schema', 'mysql', 'performance_schema', 'test');
QUERY_INPUT
))

cnt=${#userDatabases[*]}

for ((i=1; i<$cnt; i++)) 
do
	`${mysqlDumpQuery} ${userDatabases[$i]} > ${siteName}_${userDatabases[$i]}`
	gzip ${siteName}_${userDatabases[$i]}
	
	echo ${userDatabases[$i]}
done
