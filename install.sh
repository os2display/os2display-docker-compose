#!/bin/bash

source scripts/functions.sh

# Necessary variables
ENV_FILE="./.env"
DB_TEST_COUNT=15

# Install all the dependencies, if missing.
install_dependencies

docker network create frontend
docker network create -d bridge app

if test -f "$ENV_FILE"; then
	printf "%s seems to exist already, installing automatically.\n" "$ENV_FILE"
	source "$ENV_FILE"
	initiate "$APP_DATABASE_URL" "$DB_TEST_COUNT" "$ENV_FILE"
	exit
else
	printf "%s does not exist. Installing interactively.\n" "$ENV_FILE"

	read -rep $'What domain are you going to use?: ' DOMAIN

	read -rep $'[1]: If you already have a MariaDB server\n[2]: If you want to use the included MariaDB image\n' MARIADB
	if [[ "$MARIADB" -ne 1 && "$MARIADB" -ne 2 ]]; then
		printf "You have to choose either 1 or 2!";
	fi

	# Create necessary variables for database connection
	if [[ "$MARIADB" -eq 1 ]]; then
		read -rep $'Database Username: ' DB_USER
		read -rep $'Database Password: ' DB_PASS
		read -rep $'Database Name: ' DB_NAME
		read -rep $'Database Host: ' DB_HOST
		read -rep $'Database Port: ' DB_PORT
		read -rep $'MariaDB Version: ' DB_VERSION
		DSN="mysql:\/\/$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT\/$DB_NAME?serverVersion=mariadb-$DB_VERSION"
	elif [[ "$MARIADB" -eq 2 ]]; then
		DSN=$(autogenerate_dsn)
		# shellcheck disable=SC2034
		CLEAN_DSN=$(echo "$DSN" | sed 's/\\//g')
		DB_USER=$(echo "$CLEAN_DSN" | grep -oP "mysql://\K(.+?):" | cut -d: -f1)
		DB_PASS=$(echo "$CLEAN_DSN" | grep -oP "mysql://.*:\K(.+?)@" | cut -d@ -f1)
		DB_HOST=$(echo "$CLEAN_DSN" | grep -oP "mysql://.*@\K(.+?):" | cut -d: -f1)
		DB_PORT=$(echo "$CLEAN_DSN" | grep -oP "mysql://.*@.*:\K(\d+)/" | cut -d/ -f1)
		DB_NAME=$(echo "$CLEAN_DSN" | grep -oP "mysql://.*@.*:.*/\K(.+?)$" | cut -f1 -d"?")
	fi

	# Autogenerate the rest
	JWT_PASSPHRASE=$(generate_random_string_base64)
	SECRET=$(generate_random_string_base64)
	DB_ROOT_PASS=$(generate_random_string)

	# Update .env file
	printf "Copying .env.example to .env\n"
	cp .env.example $ENV_FILE
	printf "Updating .env file\n"
	sed -i "s/=DB_USER/=$DB_USER/g" $ENV_FILE
	sed -i "s/=DB_PASS/=$DB_PASS/g" $ENV_FILE
	sed -i "s/=DB_ROOT_PASS/=$DB_ROOT_PASS/g" $ENV_FILE
	sed -i "s/=DB_NAME/=$DB_NAME/g" $ENV_FILE
	sed -i "s/=JWT_PASSPHRASE/=$JWT_PASSPHRASE/g" $ENV_FILE
	sed -i "s/=SECRET/=$SECRET/g" $ENV_FILE
	sed -i "s/=\"DSN/=\"$DSN/g" $ENV_FILE
	sed -i "s/=DOMAIN/=$DOMAIN/g" $ENV_FILE
	sed -i "s/https:\/\/DOMAIN/https:\/\/$DOMAIN/g" $ENV_FILE
	sed -i "s/DOMAIN:8093/$DOMAIN:8093/g" $ENV_FILE

	initiate "$DSN" "$DB_TEST_COUNT"

	printf "And now you're done!\n"
fi