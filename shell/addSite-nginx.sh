#!/bin/bash
# Domain (without the www.)
# Usage   addSite-nginx.sh <domain>

DOMAIN=$1
ROOT_PATH="/var/www/s/$DOMAIN"
SOCK_PATH="$ROOT_PATH/.sock"
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
mkdir $LOG_PATH
mkdir $SOCK_PATH
mkdir "$ROOT_PATH/tmp"

# Make sure nginx can read the files
chmod 0755 $WEB_PATH

#Create the user group
groupadd $USER

#add the user
useradd -g $USER -s /bin/bash -d "$ROOT_PATH" $USER

echo '\nEnter the users new shell password'

passwd $USER 

#Chown it
chown -R $USER:$USER $ROOT_PATH
chown -R $USER:www-data $SOCK_PATH

# @todo change the main nginx.conf file

###### Create the NGINX default config ######
echo "upstream ${USER}fpm {
	server unix:$SOCK_PATH/php5-fpm.sock;
}

server {
    listen 80;

    server_name $DOMAIN *.$DOMAIN;
    
    # Rewrite all www. to non www. for SEO purposes
    if (\$host ~* www\.(.*)) {
        rewrite ^(.*)$ http://$DOMAIN\$1 permanent;
    }

    access_log  $LOG_PATH/access.log;
    error_log $LOG_PATH/error.log;

    root $WEB_PATH;
    
    # Ignore favicon
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }
    
    # Disable logging for robots.txt
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # Deny all attempts to access hidden files such as .htaccess, .htpasswd, .DS_Store (Mac).
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Assets
    location ~ \.(js|css|png|jpg|gif|swf|ico|pdf|mov|fla|zip|rar)$ {
        # expires 24h;
        log_not_found off;
        try_files \$uri =404;
    }

    location / {
        index index.php;
        if (!-e \$request_filename) {
            rewrite ^(.*)$  /index.php last;
        }
    }

    location ~ (.*)?.php($|/) {
        if (!-f \$request_filename) {
            return 404;
        }

        fastcgi_index index.php;
        fastcgi_split_path_info ^(.+.php)(.*)$;
        include /etc/nginx/fastcgi_params;
        fastcgi_pass ${USER}fpm;
    }
}" > /etc/nginx/sites-available/$DOMAIN

# Setup the php-fpm config file
echo "[$USER]
listen = $SOCK_PATH/php5-fpm.sock
listen.owner = $USER
listen.group = www-data
listen.mode = 0660
user = $USER
group = www-data
pm = dynamic
pm.max_children = 10
pm.start_servers = 5
pm.min_spare_servers = 2
pm.max_spare_servers = 5
pm.max_requests = 800
request_terminate_timeout = 30s
slowlog = /var/log/fpm/fpm-$USER-slow.log

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

if [ -f "/etc/php5/fpm/pool.d/www.conf" ]
then
	rm /etc/php5/fpm/pool.d/www.conf
fi

#Write the NGINX File
ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

# Reload the nginx server to load the new site.
service nginx reload
service php5-fpm restart