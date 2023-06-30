#!/bin/bash

source scripts/functions.sh

create_user=0
create_admin=0
create_tenant=0
restart=0
start=0
stop=0
logs=0
db_dump=0
create_dump_crontab=0

#---
## Explains the usage of the scripts
#---
usage(){
>&2 cat << EOF
Usage: $0
	[ -u | --create-user ]
	[ -a | --create-admin ]
	[ -t | --create_tenant ]
	[ -r | --restart ]
	[ -s | --start ]
	[ -S | --stop ]
	[ -l | --logs ]
	[ -d | db-dump ]
	[ -c | create-dump-crontab ]
	[ -h | --help ]
You may write "help" after the options above
EOF
	exit 1
}

args=$(getopt -a -o uathrsSldc --long create-user,create-admin,create-tenant,help,restart,start,stop,logs,db-dump,create-dump-crontab -- "$@")
if [[ "$?" -gt 0 ]]; then
	usage
fi

eval set -- "${args}"
while :
do
	case $1 in
		-u | --create-user) create_user=1 ; shift ;;
		-a | --create-admin) create_admin=1 ; shift ;;
		-t | --create-tenant) create_tenant=1 ; shift ;;
		-r | --restart) restart=1 ; shift ;;
		-s | --start) start=1 ; shift ;;
		-S | --stop) stop=1 ; shift ;;
		-l | --logs) logs=1 ; shift ;;
		-d | --db-dump) db_dump=1; shift ;;
		-c | --create-dump-crontab) create_dump_crontab=1; shift ;;
		-h | --help) usage ; shift ;;
		# -- means the end of the arguments; drop this, and break out of the while loop
		--) shift; break ;;
		*) >&2 echo Unsupported option: "$1"
			usage ;;
	esac
done

if [[ $create_user -eq 1 ]]; then
	if [[ $1 = "help" ]]; then
		printf "%s --create-user [<email> [<password> [<full-name>]]]\n" "$0"
		exit 1
	fi
	create_user "$@"
elif [[ $create_admin -eq 1 ]]; then
	if [[ $1 = "help" ]]; then
		printf "%s --create-admin [<email> [<password> [<full-name>]]]\n" "$0"
		exit 1
	fi
	create_admin "$@"
elif [[ $create_tenant -eq 1 ]]; then
	if [[ $1 = "help" ]]; then
		printf "%s --create-tenant [<tenantKey> [<title> [<description>]]]\n" "$0"
		exit 1
	fi
	create_tenant "$@"
elif [[ $restart -eq 1 ]]; then
	if [[ $1 = "help" ]]; then
		printf "%s --restart [<containers>]\n" "$0"
		exit 1
	fi
	restart "$@"
elif [[ $start -eq 1 ]]; then
	if [[ $1 = "help" ]]; then
		printf "%s --start [<containers>]\n" "$0"
		exit 1
	fi
	start "$@"
elif [[ $stop -eq 1 ]]; then
	if [[ $1 = "help" ]]; then
		printf "%s --stop [<containers>]\n" "$0"
		exit 1
	fi
	stop "$@"
elif [[ $logs -eq 1 ]]; then
	if [[ $1 = "help" ]]; then
		printf "%s --logs [<# of lines> [follow [service]]]\n" "$0"
		exit 1
	fi
	logs "$@"
elif [[ $db_dump -eq 1 ]]; then
	if [[ $1 = "help" ]]; then
		printf "%s --db-dump\n" "$0"
		printf "\tExamples:\n\t./os2display.sh --db-dump > dump.sql\n\t./os2display.sh --db-dump | gzip > dump.sql.gz\n"
		exit 1
	fi
	db_dump "$@"
elif [[ $create_dump_crontab -eq 1 ]]; then
	if [[ $1 = "help" ]]; then
		printf "%s --create-dump-crontab <crontab-time> <path> [gzip]\n" "$0"
		printf "\tExamples:\n\t./os2display.sh --create-dump-crontab '0 2 * * *' /var/lib/os2display-db-dumps\n\t./os2display.sh --create-dump-crontab '30 1 * * *' /var/lib/os2display-db-dumps gzip\n"
		exit 1
	fi
	create_dump_crontab "$@"
fi

exit 0