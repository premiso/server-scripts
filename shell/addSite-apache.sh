#!/bin/bash
#
# Usage   addsite.sh <domain>

DOMAIN=$1
ROOT_PATH="/var/www/s/$DOMAIN"
WEB_PATH="$ROOT_PATH/htdocs"
LOG_PATH="$ROOT_PATH/logs"

if [[ $1 =~ ^(.*)\..*$ ]]
then
        USER=${BASH_REMATCH[1]}
else
        echo "Invalid domain $1 passed in."
        exit 1;
fi

# First make the paths
mkdir -p $WEB_PATH
mkdir $LOG_PATH $ROOT_PATH/cgi-bin $ROOT_PATH/.socks

#Create the user group
groupadd $USER

#add the user
useradd -g $USER -s /bin/sh -d "$ROOT_PATH" $USER

# Allow the www-data
# removed for security reasons
#usermod -a -G www-data $USER
#usermod -a -G $USER www-data

# @todo, need to test this with the permissions stuff
#Chown it
chown -R $USER:$USER $ROOT_PATH
#chown -R www-data:www-data $ROOT_PATH/cgi-bin
#chown -R www-data:www-data $ROOT_PATH/.socks

###### Create the APACHE default config ######
echo "<VirtualHost *:80>
        SuexecUserGroup $USER $USER

        ServerName $DOMAIN
        ServerAlias *.$DOMAIN
        ServerAdmin admin@$DOMAIN
        
        DocumentRoot $WEB_PATH

        FastCgiExternalServer $ROOT_PATH/cgi-bin/php5.ext -socket $ROOT_PATH/.socks/$USER.sock
        Alias /cgi-bin/ $ROOT_PATH/cgi-bin/

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
listen = $ROOT_PATH/.socks/$USER.sock
listen.owner = $USER
listen.group = $USER
listen.mode = 0660

user = $USER
group = $USER

pm = dynamic
pm.max_children = 6
pm.start_servers = 2
pm.min_spare_servers = 2
pm.max_spare_servers = 8
pm.max_requests = 0
request_terminate_timeout = 30s
slowlog = /var/log/apache/fpm-$USER-slow-nami.log

env[HOME] = $ROOT_PATH
env[USER] = $USER
env[TMP] = $ROOT_PATH/tmp
env[TMPDIR] = $ROOT_PATH/tmp
env[TEMP] = $ROOT_PATH/tmp
env[DOCUMENT_ROOT] = $ROOT_PATH/htdocs

; Custom PHP.ini configuration
php_admin_value[open_basedir] = "$ROOT_PATH"
php_value[include_path]=".:$ROOT_PATH/htdocs:$ROOT_PATH/htdocs/include"

; UPLOAD
php_admin_flag[file_uploads]=1
php_admin_value[upload_tmp_dir]="$ROOT_PATH/tmp"

;Maximum allowed size for uploaded files.
php_admin_value[upload_max_filesize]="50M"
php_admin_value[max_input_time]=120
php_admin_value[post_max_size]="50M"

;#### LOGS
php_admin_flag[log_errors] = on
php_admin_value[log_errors]=1
php_admin_value[display_errors]=0
php_admin_value[display_startup_errors]=0
php_admin_value[html_errors]=0
php_admin_value[define_syslog_variables]=0
php_value[error_reporting]=6143

; Maximum execution time of each script, in seconds (30)
php_value[max_input_time]="45"

; Maximum amount of time each script may spend parsing request data
php_value[max_execution_time]="120"

; Maximum amount of memory a script may consume (8MB)
php_value[memory_limit]="128M"

; Sessions: IMPORTANT reactivate garbage collector on Debian!!!
php_value[session.gc_maxlifetime]=3600
php_admin_value[session.gc_probability]=1
php_admin_value[session.gc_divisor]=100
php_admin_value[session.save_path]=$ROOT_PATH/tmp

; SECURITY
php_admin_value[magic_quotes_gpc]=0
php_admin_value[register_globals]=0
php_admin_value[session.auto_start]=0
;php_admin_value[mbstring.http_input]="pass"
;php_admin_value[mbstring.http_output]="pass"
php_admin_value[mbstring.encoding_translation]=0
php_admin_value[expose_php]=0
php_admin_value[allow_url_fopen]=1
php_admin_value[safe_mode]=0
php_admin_value[cgi.fix_pathinfo]=1
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
#
