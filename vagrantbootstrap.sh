#!/usr/bin/env bash

VAGRANT_HOME="/home/vagrant"
BOOTSTRAP_ROOT="$VAGRANT_HOME/.vagrantboostrap"

# Fix "stdin: is not a tty"
# 
# From: https://github.com/myplanetdigital/vagrant-ariadne/commit/dd0592d05d4f5c881640540fdc43d8396e00ddd7
#
# If last line is `mesg n`, replace with conditional.
if [ "`tail -1 /root/.profile`" = "mesg n" ]
then
  echo 'Fixing future `stdin: is not a tty` errors...'
  sed -i '$d' /root/.profile
  cat << 'EOH' >> /root/.profile
  if `tty -s`; then
    mesg n
  fi
EOH
fi

# Make sure bootstrap root exists
if [ ! -d $BOOTSTRAP_ROOT ];
then
	mkdir $BOOTSTRAP_ROOT
fi

# LAMP Install
if [ ! -f "$BOOTSTRAP_ROOT/LAMP" ];
then
	touch "$BOOTSTRAP_ROOT/LAMP"

	# Update first
	sudo apt-get update 2>/dev/null

	# MySQL set root pwd
	sudo debconf-set-selections <<< 'mysql-server-5.5  mysql-server/root_password password root'
	sudo debconf-set-selections <<< 'mysql-server-5.5  mysql-server/root_password_again password root'
	sudo apt-get -y install mysql-server 2>/dev/null

	# Install apache/php etc.
	apt-get install vim apache2 php5 libapache2-mod-php5 php5-mysql php5-gd php5-curl curl unzip imagemagick git-core -y 2>/dev/null
	
	# Fix ServerName Errors
	echo ServerName $HOSTNAME > /etc/apache2/conf.d/fqdn

	# Enable modules
	sudo a2enmod rewrite
	sudo a2enmod headers
	sudo a2enmod expires

	# Change port in ports.conf and remove NameVirtualHost line
	sed -e '/NameVirtualHost/d' -e 's/80/8080/' /etc/apache2/ports.conf 1> $VAGRANT_HOME/ports.conf
	mv $VAGRANT_HOME/ports.conf /etc/apache2/ports.conf

	cp /vagrant/config_files/default /etc/apache2/sites-available/default

	ln -s /vagrant/www/ www

	service apache2 restart
fi