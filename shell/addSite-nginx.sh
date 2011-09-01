#!/bin/bash
#
# Usage   addSite-nginx.sh <domain>

DOMAIN=$1
WEB_PATH="/var/www/s/$DOMAIN/htdocs"
LOG_PATH="/var/www/s/$DOMAIN/logs"

if [[ $1 =~ ^(.*)\..*$ ]]
then
        USER=${BASH_REMATCH[1]}
else
        echo "Invalid domain $1 passed in."
        exit 1;
fi

# First make the paths
mkdir -p $WEB_PATH
mkdir $LOG_PATH

#Create the user group
groupadd $USER

#add the user
useradd -G www-data -g $USER -s /bin/sh -d "$WEB_PATH/../" $USER

#Chown it
chown -R $USER:$USER $WEB_PATH/../

###### Create the NGINX default config ######
echo "server {
        listen 80 default;

        server_name $DOMAIN *.$DOMAIN;

        access_log  $LOG_PATH/$DOMAIN.access.log;
        error_log $LOG_PATH/$DOMAIN.error.log;

        root $WEB_PATH;

        location / {
                index  index.html index.htm index.php;
        }

        location ~ (.*)?.php($|/) {
                if (!-f \$request_filename) {
                        return 404;
                }

                fastcgi_index index.php;
                fastcgi_split_path_info ^(.+.php)(.*)$;
                include /etc/nginx/fastcgi_params;
                fastcgi_pass 127.0.0.1:9000;
        }
}" > /etc/nginx/sites-available/$DOMAIN

# Setup the php-fpm config file
echo "[$USER]
listen = 127.0.0.1:9000
listen.owner = $USER
listen.group = $USER
listen.mode = 0660
user = $USER
group = $USER
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 2
pm.max_spare_servers = 10
pm.max_requests = 0
request_terminate_timeout = 305
slowlog = /var/log/apache/fpm-$USER-slow.log
" >> /etc/php5/fpm/pool.d/$USER.conf


#Write the NGINX File
ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

# Reload the nginx server to load the new site.
service nginx reload
service php5-fpm restart
