#!/bin/bash

#---
## Automatically generates a MYSQL DSN
#---
autogenerate_dsn () {
	DB_USER=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 4 ; echo 'os2display')
	DB_PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32 ; echo '')
	DB_NAME=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 4 ; echo '_os2display')
	DB_HOST='mariadb'
	DB_PORT='3306'
	DB_VERSION="10.11.4"
	echo "mysql:\/\/$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT\/$DB_NAME?serverVersion=mariadb-$DB_VERSION"
}

#---
## Generates a random 32 character string with special characters and then encodes it with BASE64
#---
generate_random_string_base64 () {
	STRING=$(tr -dc 'A-Za-z0-9.,;:!"#æøåÆØÅðÐþÞ' </dev/urandom | head -c 32 ; echo '')
	echo "$STRING" | base64
}

#---
## Generates a random 32 character string
#---
generate_random_string () {
	tr -dc A-Za-z0-9 </dev/urandom | head -c 32 ; echo ''
}

#---
## Tests MySQL connection
## Should be used with the following parameters:
## - DATABASE_USER
## - DATABASE_PASSWORD
## - DATABASE_HOST
## - DATABASE_PORT
## - DATABASE_NAME
#---
test_db_connection () {
	DATABASE_USER=$1
	DATABASE_PASSWORD=$2
	DATABASE_HOST=$3
	DATABASE_PORT=$4
	DATABASE_NAME=$5
	DB_TEST_COUNT=$6
	# Set default variables
	COUNTER=0
	if [[ -z "$DB_TEST_COUNT" ]]; then
		DB_TEST_COUNT=10
	fi

	printf "Testing database connection.\n"
	printf "Going to test at most %s times.\n" "$DB_TEST_COUNT"

	# Loop until COUNTER finishes
	while : ; do

		# Take a nap
		sleep 1

		# Using the api container to try to connect to the MariaDB database, and see if our database exists
		DB_EXISTS=$(sudo docker compose exec api \
			mysql \
				--user="$DATABASE_USER" \
				--password="$DATABASE_PASSWORD" \
				--host="$DATABASE_HOST" \
				--port="$DATABASE_PORT" \
				-e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$DATABASE_NAME'" \
				| grep "$DATABASE_NAME")

		# Check if database exists
		if [[ -n "$DB_EXISTS" ]]; then
			printf "Database \"%s\" is available.\n" "$DB_EXISTS"
			# Break out of loop if it does
			break
		fi

		# If the maximum is reached, then exit
		if [[ "$COUNTER" -eq "$DB_TEST_COUNT" ]]; then
			printf "Hit maximum number of tries; exiting!\n"
			exit 1
		fi

		# Increment counter
		((COUNTER++))
	done
}

#---
## Migrates database and imports templates and screen layouts
#---
migrate_and_import () {
	# Migrate the database
	printf "Migrating database\n"
	sudo docker compose exec --user deploy api bin/console doctrine:migrations:migrate --no-interaction

	# Import templates
	printf "Importing templates\n"
	sudo docker compose exec --user deploy api bin/console app:template:load https://raw.githubusercontent.com/os2display/display-templates/main/build/book-review-config-main.json
	sudo docker compose exec --user deploy api bin/console app:template:load https://raw.githubusercontent.com/os2display/display-templates/main/build/calendar-config-main.json
	sudo docker compose exec --user deploy api bin/console app:template:load https://raw.githubusercontent.com/os2display/display-templates/main/build/contacts-config-main.json
	sudo docker compose exec --user deploy api bin/console app:template:load https://raw.githubusercontent.com/os2display/display-templates/main/build/iframe-config-main.json
	sudo docker compose exec --user deploy api bin/console app:template:load https://raw.githubusercontent.com/os2display/display-templates/main/build/image-text-config-main.json
	sudo docker compose exec --user deploy api bin/console app:template:load https://raw.githubusercontent.com/os2display/display-templates/main/build/instagram-feed-config-main.json
	sudo docker compose exec --user deploy api bin/console app:template:load https://raw.githubusercontent.com/os2display/display-templates/main/build/poster-config-main.json
	sudo docker compose exec --user deploy api bin/console app:template:load https://raw.githubusercontent.com/os2display/display-templates/main/build/rss-config-main.json
	sudo docker compose exec --user deploy api bin/console app:template:load https://raw.githubusercontent.com/os2display/display-templates/main/build/slideshow-config-main.json
	sudo docker compose exec --user deploy api bin/console app:template:load https://raw.githubusercontent.com/os2display/display-templates/main/build/table-config-main.json
	sudo docker compose exec --user deploy api bin/console app:template:load https://raw.githubusercontent.com/os2display/display-templates/main/build/travel-config-main.json
	sudo docker compose exec --user deploy api bin/console app:template:load https://raw.githubusercontent.com/os2display/display-templates/main/build/video-config-main.json

	# Import screen layouts
	printf "Importing screen layouts\n"
	sudo docker compose exec --user deploy api bin/console app:screen-layouts:load --update --cleanup-regions https://raw.githubusercontent.com/os2display/display-templates/main/src/screen-layouts/full-screen.json
	sudo docker compose exec --user deploy api bin/console app:screen-layouts:load --update --cleanup-regions https://raw.githubusercontent.com/os2display/display-templates/main/src/screen-layouts/three-boxes-horizontal.json
	sudo docker compose exec --user deploy api bin/console app:screen-layouts:load --update --cleanup-regions https://raw.githubusercontent.com/os2display/display-templates/main/src/screen-layouts/three-boxes.json
	sudo docker compose exec --user deploy api bin/console app:screen-layouts:load --update --cleanup-regions https://raw.githubusercontent.com/os2display/display-templates/main/src/screen-layouts/touch-template.json
	sudo docker compose exec --user deploy api bin/console app:screen-layouts:load --update --cleanup-regions https://raw.githubusercontent.com/os2display/display-templates/main/src/screen-layouts/two-boxes.json
	sudo docker compose exec --user deploy api bin/console app:screen-layouts:load --update --cleanup-regions https://raw.githubusercontent.com/os2display/display-templates/main/src/screen-layouts/two-boxes-vertical.json
	sudo docker compose exec --user deploy api bin/console app:screen-layouts:load --update --cleanup-regions https://raw.githubusercontent.com/os2display/display-templates/main/src/screen-layouts/six-areas.json
	sudo docker compose exec --user deploy api bin/console app:screen-layouts:load --update --cleanup-regions https://raw.githubusercontent.com/os2display/display-templates/main/src/screen-layouts/four-areas.json
}

#---
## Creates a tenant for OS2Display
#---
create_tenant () {
	docker compose exec api php bin/console app:tenant:add "$@"
}

#---
## Creates a tenant for OS2Display; for use by the initiate function
#---
sudo_create_tenant () {
	sudo docker compose exec api php bin/console app:tenant:add "$@"
}

#---
## Creates a user for OS2Display
#---
create_user () {
	docker compose exec api php bin/console app:user:add "$@"
}

#---
## Creates an administrator user for OS2Display
#---
create_admin () {
	docker compose exec api php bin/console app:user:add --admin "$@"
}

#---
## Creates an administrator user for OS2Display; for use by the initiate function
#---
sudo_create_admin () {
	sudo docker compose exec api php bin/console app:user:add --admin "$@"
}

#---
## Checks whether or not the current user is in the docker group or not
#---
check_docker_group () {
	echo "Checking if user is in docker group".
	echo "If you have just added your user in the docker group in the currently running session,"
	echo "you may want to refresh your session, e.g. by logging out and logging in again."

	# Get the output of the groups command and check if "docker" appears in the groups
	DOCKER_GROUP=$(groups | sed 's/ /\n/g' | grep "docker")

	if [[ -z "$DOCKER_GROUP" ]]; then
		>&2 echo "Your user is not in the docker group!"
		>&2 echo "Adding you to the docker group, but you have to refresh your shell, e.g. by logging out and logging in again."
		>&2 echo "Once you have refreshed your shell, just rerun the install script."
		>&2 echo "You have been added to the docker group, and the script is exiting for you to refresh your shell."
		[ $(sudo getent group docker) ] || sudo groupadd docker
		sudo usermod -aG docker $(echo $USER)
		exit 5
	fi
}

#---
## Check git branch
#---
check_git_branch () {
	echo "##### GIT INFORMATION #####"
	REMOTE=$(git remote get-url origin)
	BRANCH=$(git rev-parse --abbrev-ref HEAD)
	printf 'GIT BRANCH: %s\n' "$BRANCH"
	printf 'GIT REMOTE: %s\n' "$REMOTE"
	echo "###########################"
}

#---
## Restarts all or specified containers
#---
restart () {
	docker compose restart "$@"
	docker compose exec client mkdir -p /var/www/html/client/
	docker compose exec client ln -s /var/www/html/static /var/www/html/client/
	docker compose exec client ln -s /var/www/html/config.json /var/www/html/client/
	docker compose exec client ln -s /var/www/html/release.json /var/www/html/client/
}

#---
## Starts all or specified containers
#---
start () {
	docker compose up "$@" -d
	docker compose exec client mkdir -p /var/www/html/client/
	docker compose exec client ln -s /var/www/html/static /var/www/html/client/
	docker compose exec client ln -s /var/www/html/config.json /var/www/html/client/
	docker compose exec client ln -s /var/www/html/release.json /var/www/html/client/
}

#---
## Stops all or specified containers
#---
stop () {
	docker compose stop "$@"
}

#---
## Restarts all or specified containers
#---
logs () {
	ARGUMENTS_PASSED=0

	if [[ -n "$1" ]]; then
		ARGUMENTS_PASSED=1
	fi
	if [[ -n "$2" ]];then
		ARGUMENTS_PASSED=2
	fi
	if [[ -n "$3" ]];then
		ARGUMENTS_PASSED=3
	fi

	case "$ARGUMENTS_PASSED" in
		0) docker compose logs ;;
		1) docker compose logs --tail "$1" ;;
		2) docker compose logs --tail "$1" -f ;;
		3) docker compose logs --tail "$1" -f "$3" ;;
		*) >&2 echo Unsupported option: "$1" ;;
	esac
}

#---
## Restarts all or specified containers
#---
db_dump () {
	source .env
	docker compose exec api mysqldump -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" -h"$DB_HOST" "$MARIADB_DATABASE"
}

#---
## Creates a cronjob for db dumps
#---
create_dump_crontab () {
	SCRIPT_PATH=$(realpath "$0")

	if [[ -n "$3" ]]; then
		crontab -l | { cat; echo "$1 $SCRIPT_PATH -d | gzip > $2/os2display_dump-\$(date +\%Y-\%m-\%d-\%H\%M).sql.gz"; } | crontab -
	else
		crontab -l | { cat; echo "$1 $SCRIPT_PATH -d > $2/os2display_dump-\$(date +\%Y-\%m-\%d-\%H\%M).sql"; } | crontab -
	fi
}

#---
## Installs missing dependencies
#---
install_dependencies () {

	printf "Going to test for dependencies\n"

	# Determine distribution
	DISTRO=$(awk -F= '/^ID/{print $2}' /etc/os-release | sed 's/"//g' | head -n1)

	if [[ "$DISTRO" != "debian" && "$DISTRO" != "ubuntu" ]]; then
		ID_LIKE=$(awk -F= '/^ID_LIKE/{print $2}' /etc/os-release | sed 's/"//g' | awk '{print $1}')
		if [[ "$ID_LIKE" = "debian" || "$ID_LIKE" = "ubuntu" ]]; then
			DISTRO="$ID_LIKE"
		else
			printf "Automatic install of dependencies currently not supported on this distribution.\nWill check if necessary packages are installed already, then perhaps we can continue regardless.\n"
		fi
	fi

	DEPENDENCIES=( "nginx" "docker" "certbot" )
	for DEP in "${DEPENDENCIES[@]}"; do
		# Check if DEP is installed already
		DEP_INSTALLED=$(sudo which $DEP)

		if [[ -z "$DEP_INSTALLED" ]]; then
			# If not a debian or ubuntu like distro, tell the user they need to install the necessary dependencies
			if [[ "$DISTRO" != "debian" && "$DISTRO" != "ubuntu" ]]; then
				printf "%s not installed! You need the following to continue: " "$DEP"
				echo "${DEPENDENCIES[@]}"
				printf "\nExiting!\n"
				exit 2
			else # If a debian or ubuntu like distro, attempt to install the missing dependency

				# We need the below for most of these:
				sudo apt update -y -q
				sudo apt install curl ca-certificates gnupg python3 python3-venv libaugeas0 -y -q

				if [[ "$DEP" = "nginx" ]]; then
					URL="https://packages.sury.org/nginx/README.txt"
					# Check if script is available
					STATUS_CODE=$(curl -is "$URL" | head -n 1 | awk '{print $2}')
					if [[ "$STATUS_CODE" = "404" ]]; then
						printf "Can't install %s because %s is not reachable.\nStatus code: %s\n" "$DEP" "$URL" "$STATUS_CODE"
						exit 3
					else
						printf "Going to install %s from %s; this is going to require sudo\n" "$DEP" "$URL"
						bash <(curl -s "$URL")
						sudo apt install "$DEP" -y -q
						sudo systemctl enable nginx
						sudo systemctl start nginx
					fi
				elif [[ "$DEP" = "docker" ]]; then
					# Below is taken from here: https://docs.docker.com/engine/install/debian/ and https://docs.docker.com/engine/install/ubuntu/

						sudo install -m 0755 -d /etc/apt/keyrings
						curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
						sudo chmod a+r /etc/apt/keyrings/docker.gpg

					if [[ "$DISTRO" = "debian" ]]; then
						echo \
							"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
							"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
							sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
					elif [[ "$DISTRO" = "ubuntu" ]]; then
						echo \
							"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
							"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
							sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
					fi

					sudo apt update -y -q
					sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker docker-compose-plugin -y -q
					sudo systemctl enable docker containerd

				elif [[ "$DEP" = "certbot" ]]; then
					sudo python3 -m venv /opt/certbot/
					sudo /opt/certbot/bin/pip install --upgrade pip
					sudo /opt/certbot/bin/pip install certbot certbot-nginx
					sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
				fi
			fi
		fi
	done

	# For good measure, check again!
	for DEP in "${DEPENDENCIES[@]}"; do
		# Check if DEP is installed
		DEP_INSTALLED=$(sudo which $DEP)

		if [[ -z "$DEP_INSTALLED" ]]; then
			printf "%s not installed! Attempted installation seems to have failed!\nYou need the following to continue; please manually install these: " "$DEP"
			echo "${DEPENDENCIES[@]}"
			printf "\nExiting!\n"
			exit 4
		fi
	done

	printf "Dependencies installed. Continuing with installation of OS2Display.\n"
}

#---
## Initiates OS2Display
#---
initiate () {

	if [[ -z "$DSN" ]]; then
		DSN=$APP_DATABASE_URL
	fi

	# Pull images
	printf "### Initiating OS2Display ###\nPulling images...\n"
	sudo docker compose pull
	sleep 2
	# Create necessary folders
	printf "Creating necessary directories if they're missing.\n"
	mkdir -p jwt media
	# Start containers
	printf "Starting containers...\n"
	sudo docker compose up -d

	# Clean DSN
	# shellcheck disable=SC2001
	CLEAN_DSN=$(echo "$DSN" | sed 's/\\//g')

	# Get the various necessary variables from DSN
	DATABASE_USER=$(echo "$CLEAN_DSN" | grep -oP "mysql://\K(.+?):" | cut -d: -f1)
	DATABASE_PASSWORD=$(echo "$CLEAN_DSN" | grep -oP "mysql://.*:\K(.+?)@" | cut -d@ -f1)
	DATABASE_HOST=$(echo "$CLEAN_DSN" | grep -oP "mysql://.*@\K(.+?):" | cut -d: -f1)
	DATABASE_PORT=$(echo "$CLEAN_DSN" | grep -oP "mysql://.*@.*:\K(\d+)/" | cut -d/ -f1)
	DATABASE_NAME=$(echo "$CLEAN_DSN" | grep -oP "mysql://.*@.*:.*/\K(.+?)$" | cut -f1 -d"?")

	# Test database connection
	test_db_connection "$DATABASE_USER" "$DATABASE_PASSWORD" "$DATABASE_HOST" "$DATABASE_PORT" "$DATABASE_NAME" "$DB_TEST_COUNT"

	# Making sure this folder is available for the right user and group
	sudo docker compose exec --user root api chown -R deploy. /var/www/html/config/jwt
	sudo docker compose exec --user root api mkdir /var/www/html/media
	sudo docker compose exec --user root api chown -R deploy. /var/www/html/media
	sudo docker compose exec --user root api mkdir /var/www/html/public/media/
	sudo docker compose exec --user root api chown -R deploy. /var/www/html/public/media/

	# Moving old keypair so we can generate new ones
	# This is necessary, because old key pairs interferes with login, and results in JWT errors (500 Server Error)
	if [[ -f jwt/public.pem ]]; then
		sudo docker compose exec api php bin/console lexik:jwt:generate-keypair --overwrite
	else
		sudo docker compose exec api php bin/console lexik:jwt:generate-keypair
	fi

	# Migrate database and import templates and screen layouts
	migrate_and_import

	sudo docker compose exec client mkdir -p /var/www/html/client/
	sudo docker compose exec client ln -s /var/www/html/static /var/www/html/client/
	sudo docker compose exec client ln -s /var/www/html/config.json /var/www/html/client/
	sudo docker compose exec client ln -s /var/www/html/release.json /var/www/html/client/

	# Ask if we want to create a tenant and administrator now or later?
	read -rep $'Do you want to create a tenant and administrator now? (Y/N):' continue

	# If yes, create tenant
	if [[ $continue == [yY] || $continue == [yY][eE][sS] ]]; then
		printf "Create a tenant:\n"
		sudo_create_tenant
		printf "Create an administrator user:\n"
		sudo_create_admin
	# If not, just say how it's done
	else
		printf "\nNow you need to create a tenant and an administrator user.\n To do so, run the bellow commands:\n"
		printf "\tdocker compose exec api php bin/console app:tenant:add\n\tdocker compose exec api php bin/console app:user:add --admin"
	fi
}