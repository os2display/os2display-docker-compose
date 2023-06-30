# OS2Display

## Links to repositories and Docker images

OS2 docker images used in this project:

- [os2display-admin-client](https://hub.docker.com/r/os2display/os2display-admin-client)
- [os2display-client](https://hub.docker.com/r/os2display/os2display-client)
- [os2display-api-service-nginx](https://hub.docker.com/r/os2display/os2display-api-service-nginx)
- [os2display/os2display-api-service](https://hub.docker.com/r/os2display/os2display-api-service)

OS2 github repositories used in this project:

- [display-admin-client](https://github.com/os2display/display-admin-client)
- [display-client](https://github.com/os2display/display-client)
- [display-api-service](https://github.com/os2display/display-api-service)

## How to install OS2Display

### Custom .env file - "Automatic install"
You can choose to copy `.env.example` to `.env`, adjust the settings to your liking, and run the installation script:

```bash
./install.sh
```

It will ask for sudo, as it will try to install dependencies.

In the end it will ask if you want to create manually created tenants and administrator users.

### Interactive install

Alternatively, you can just run the installation script without a .env file, and it will create one for you:

```bash
./install.sh
```

If you don't want to use the included MariaDB service, you can shut it down and comment it out in `docker-compose.yml`

In the end it will ask if you want to create manually created tenants and administrator users.

### OpenID Connect

Currently, the installation script does not handle the setup of OpenID, so this you have to do manually by editing the `.env` file.

You'll have to edit these variables in the `.env` file to the correct values:
```dotenv
###> itk-dev/openid-connect-bundle ###
# "admin" open id connect configuration variables (values provided by the OIDC IdP)
OIDC_METADATA_URL=ADMIN_APP_METADATA_URL
OIDC_CLIENT_ID=ADMIN_APP_CLIENT_ID
OIDC_CLIENT_SECRET=ADMIN_APP_CLIENT_SECRET
OIDC_REDIRECT_URI=ADMIN_APP_REDIRECT_URI
OIDC_LEEWAY=30

APP_CLI_REDIRECT=ADMIN_CLI_REDIRECT_URI
###< itk-dev/openid-connect-bundle ###
```

### NGINX setup

NGINX is preferred as a reverse proxy. If you know your way around docker compose, you can add nginx in `docker-compose.yml`.

If you have installed OS2Display via the installation script, NGINX should be installed via apt.

To help you on your way, here is an example of a very basic NGINX conf:

```nginx
upstream api {
  server 127.0.0.1:8093;
}

upstream admin {
  server 127.0.0.1:8092;
}

upstream client {
  server 127.0.0.1:8091;
}

server {
  listen 80;
  server_name display.bellcom.dk;

  location / {
    proxy_pass http://client/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  location /admin {
    proxy_pass http://admin/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  location /v1 {
    proxy_pass http://api/v1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  location /media {
    proxy_pass http://api/media;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

### SSL/TLS Certificate

You can choose to install your own certificate, or you can use Let's encrypt.

If you have installed OS2Display via the installation script, certbot should be installed.

To install a certificate with certbot, you can run this command:
```bash
certbot -d <insert domain here>
```

Certbot will do its best to automatically renew the certificate before it expires, but if the certificate manages to expire anyway for whatever reason, you can manually renew the certificate like so:
```bash
certbot renew
```

If you have more than one certificate managed by certbot, it will also renew those if they need to be renewed.

### Good to know

#### Dependencies
The installation script will make sure the following are installed:

- NGINX
- Certbot
- Docker
- Docker Compose plugin

The installation script will try to install them on Ubuntu and Debian like systems.

The installation script is smart enough to know if you are running on a different distribution.
If you try to run the script on e.g. Rocky Linux, it cannot install the dependencies, *but* it will check if they're already installed.
If they're already installed, it will proceed to install OS2Display; if not, it will come with an error message and say which dependencies need to be installed.

If the dependencies are installed and the installation script still fails to find them, make sure they're in your `$PATH`.

#### Ports
In the end there will be three containers that will have their ports exposed (not including the MariaDB service):

- `8091`: Screen client
- `8092`: Admin client (interface is only available from /admin)
- `8093`: API / API Documentation

If you have chosen to use the included MariaDB service the port will be the standard port `3306`.

#### Database migration, templates, screen layouts

Don't worry about this part, as the installation script handles this automatically. :)

#### Can I still run `docker compose` commands myself?

Absolutely.

## Management script: os2display.sh

A management script is included to make it easier to manage OS2Display from the terminal: `os2display.sh`

It is written in bash to avoid any dependencies; no need to install Python, PHP, or any other runtimes.

Here is an overview of all the commands currently available in the script (examples further down):

```
./os2display.sh --help
./os2display.sh --create-user [<email> [<password> [<full-name>]]]
./os2display.sh --create-admin [<email> [<password> [<full-name>]]]
./os2display.sh --create-tenant [<tenantKey> [<title> [<description>]]]
./os2display.sh --restart [<containers>]
./os2display.sh --start [<containers>]
./os2display.sh --stop [<containers>]
./os2display.sh --logs [#-of-lines [follow] [service]]]
./os2display.sh --db-dump
./os2display.sh --create-dump-crontab <crontab-time> <path> [gzip]
```

### Examples

```bash
# Creates a user non-interactively
./os2display.sh --create-user example@example.com 'Iamverysecure' 'John Doe'
# Creates a user interactively
./os2display.sh --create-user
# Creates an administrator non-interactively
./os2display.sh --create-admin example@example.com 'Iamverysecure' 'John Doe'
# Creates an administrator interactively
./os2display.sh --create-admin
# Creates a tenant non-interactively
./os2display.sh --create-tenant 'TenantKey' 'Tenant' 'Tenant Description'
# Creates a tenant interactively
./os2display.sh --create-tenant
# Starts all containers
./os2display.sh --start
# Starts a single container
./os2display.sh --start mariadb
# Starts two containers
./os2display.sh --start mariadb api
# Restarts all containers
./os2display.sh --start
# Restarts a single container
./os2display.sh --restart mariadb
# Restarts two containers
./os2display.sh --restart mariadb api
# Stops all containers
./os2display.sh --stop
# Stops a single container
./os2display.sh --stop mariadb
# Stops two containers
./os2display.sh --stop mariadb api
# Dumps database to stdout
./os2display.sh --dump-db
# Dumps database to SQL file
./os2display.sh --dump-db > dump.sql
# Dumps database to gzpped SQL file:
./os2display.sh --dump-db | gzip > dump.sql.gz
# Creates a cronjob for dumping the database regularly (for backup!)
./os2display.sh --create-dump-crontab '0 2 * * *' /var/lib/os2display-db-dumps
# Creates a cronjob for dumping the database regularly (for backup!) but also gzip the dumps
./os2display.sh --create-dump-crontab '0 2 * * *' /var/lib/os2display-db-dumps gzip
```

### Short options

There are also short options available for each option shown above:

- `-u` == `--create-use`
- `-a` == `--create-admin`
- `-t` == `--create-tenant`
- `-r` == `--restart`
- `-s` == `--start`
- `-S` == `--stop`
- `-l` == `--logs`
- `-d` == `--db-dump`
- `-c` == `--create-dump-crontab`
- `-h` == `--help`

## How to use OS2Display

OS2Display comes in three main components:

- an API
  - The API talks with every component, including the database; in other words, the API is the middleman so everyone can talk to each other.
- an administration client
  - The administration client handles slides, media, screens, campaigns, and so on.
- and a screen client
  - The screen client displays certain slideshows and campaigns selected specifically for it.

### After installation

Just after installation, you should be able to access OS2Display's two clients:

- The screen client
- The administration client

The screen client will look like this if everything is set up correctly:
![Screenshot 2023-06-28 at 16-16-57 OS2Display.png](doc_images/Screenshot%202023-06-28%20at%2016-16-57%20OS2Display.png)

The administration client will look like this if everything is set up correctly:
![Screenshot 2023-06-28 at 16-19-25 OS2Display admin.png](doc_images%2FScreenshot%202023-06-28%20at%2016-19-25%20OS2Display%20admin.png)

If you have created an administrator user via the administration script or if you have created one later with the management script, you should be able to log in with all permissions.
**You need to be an administrator to manage screens.**

**Note:** If you have OpenID set up, the administration client login screen will look different.

When you have logged in, as an administrator user, you should have access to everything:
![Screenshot 2023-06-28 at 16-48-12 OS2Display admin.png](doc_images%2FScreenshot%202023-06-28%20at%2016-48-12%20OS2Display%20admin.png)

### Setting up a screen

To create a screen, you can do it from three locations:

- The "+" icon next to "Skærme"
- On the top right, the blue button "Opret"
- If you're in the screen overview, you can click on "Opret ny skærm" on the top right in that view

It is pretty straight forward to create a screen:

- Give it a name
- Potentially a description
- Put it in a group (if there are any)
- Supply the screen location
  - The screen location is found on the screen client, in the bottom right corner is a code. This is where you put that code.
- Select the screen resolution (HD or 4K)
- Select orientation (vertical or horizontal)
- A layout

Spillelister and Farveskema is not something we're going to touch on right now.

Click "Gem skærm", and you should now see the screen in the screen overview.

### Create a slide

Creating slides is similar to screens.

- Give it a name
- Choose one of the many templates
- Set up the slide according to the template; this varies from template to template.
- Save the slide

If you for some reason have an issue with saving the slide or any media, you may want to run this command:

```bash
docker compose exec --user root api chown -R deploy. /var/www/html/public/media/
```

### Create a playlist

Again, creating a playlist is much the same as the previous two.

- Give it a name
- Potentially a description
- Select which slides should be part of this playlist
- You can plan very flexibly when this playlist will be shown during the day.
- Save your playlist

### Using the playlist on a screen

- Go back to the screen you created
- Connect the screen with the code shown on the screen client ("Tilkobl")
- Scroll down to "Spillelister tilknyttet regionen"
- Select your playlist
- Save

## Other sources

- https://os2display.github.io/display-docs/
- https://www.os2.eu/os2display
