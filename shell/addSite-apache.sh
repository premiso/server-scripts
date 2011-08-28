#!/bin/bash
#
# Usage   addsite.sh <domain>

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

###### Create the APACHE default config ######
echo "<VirtualHost *:80>
        <Files *.php>
                Options +ExecCGI
        </Files>

        SuexecUserGroup $USER $USER

        ServerName $DOMAIN
        ServerAlias *.$DOMAIN
        ServerAdmin admin@$DOMAIN
        
        DocumentRoot $WEB_PATH

        <Directory $WEB_PATH/>
                Options +SymLinksIfOwnerMatch -Indexes -MultiViews
                AllowOverride All
                Order allow,deny
                Allow from all
        </Directory>
        
         ErrorLog $LOG_PATH/error.log

        LogLevel warn

        CustomLog $LOG_PATH/access.log combined

</VirtualHost>
" > /etc/apache2/sites-available/$DOMAIN

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
slowlog = /var/log/apache/fpm-$USER-slow-nami.log
" >> /etc/php5/fpm/pool.d/$USER.conf

# Add the user to the ftp service
echo "$USER" >> /etc/vsftpd.chroot_list

#Activate the apache site
ln -s /etc/apache2/sites-available/$DOMAIN /etc/apache2/sites-enabled/$DOMAIN

# Reload the nginx server to load the new site.
service apache2 reload
service php5-fpm restart

#
echo "Finished, please setup a password for $USER in order for FTP to work."
