#!/bin/bash
# WARNING: THIS SCRIPT IS UNTESTED RIGHT NOW, PROCEED WITH CAUTION!!!!
# 	I TAKE NO RESPONSABILITY FOR ANY DAMAGE CAUSE BY IT. USE AT YOUR OWN RISK.
# This script will install Redmine with nginx. 
# If you want different / updated versions, change the versions inside
# the code and viola, you have the updated versions.
#
# This will install passenger, nginx, ROR, Gem etc. Meant for Debian. 
# Script made from: http://sourcode.net/debian-squeeze-redmine-nginx-phusion-passenger/ 
# with a few changes, so props goto him.

read -p "This script will install ROR and other packages to abort, Ctrl+C now or press any key to continue"

apt-get install build-essential ruby1.8 ruby1.8-dev irb1.8 rdoc1.8 zlib1g-dev libruby libssl-dev libpq-dev subversion rubygems libcurl4-openssl-dev rake libmysqlclient-dev librmagick-ruby

gem install -v=1.0.1 rack
gem install fastthread
gem install -v=2.3.5 rails
gem install -v=0.5.2 i18n
gem install mysql

ln -s /usr/bin/ruby1.8 /usr/bin/ruby
ln -s /usr/bin/irb1.8 /usr/bin/irb

cd /usr/src

wget http://rubyforge.org/frs/download.php/74605/passenger-3.0.6.tar.gz
tar -xzf passenger-3.0.6.tar.gz

cd passenger-3.0.6/bin

echo "For the next step, do "Enter" then "1" then "Enter" 
read -p "Press any key to continue with the passenger nginx module install."
source passenger-install-nginx-module

cd /etc/init.d/
wget http://pastebin.com/raw.php?i=aEVberna -O nginx
chmod +x nginx

/usr/sbin/update-rc.d -f nginx defaults

cd /usr/src
wget http://rubyforge.org/frs/download.php/74419/redmine-1.1.2.tar.gz
tar -xzf readmine-1.1.2.tar.gz
cd redmine-1.1.2

# @ todo setup mysql here
echo "MySQL will need to be setup next so issue the following commands in a mysql prompt, then click any key to continue (if you need to install mysql do so) and you may need to open up another ssh instance to do this:

mysql -u root -p
Enter password:

mysql> create database redmine character set utf8;
mysql> create user ‘redmine’@'localhost’ identified by ‘my_password’;
mysql> grant all privileges on redmine.* to ‘redmine’@'localhost’;"

read -p "Any key to continue"

cd /usr/src/redmine-1.1.2/config/

echo "production:
adapter: mysql
database: redmine
host: localhost
username: redmine
password: my_password
encoding: utf8" >  databse.yml

echo "production:
   delivery_method: :sendmail" >  email.yml

NGINX_CONF=`exec wget -q -O - http://pastebin.com/raw.php?i=tY9Lp4CM`
echo $NGINX_CONF > /opt/nginx/conf/nginx.conf

rake generate_session_store
RAILES_ENV=production rake db:migrate
#@todo allow the load_default with a param

# start nginx
/etc/init.d/nginx start

echo "Script complete!"
