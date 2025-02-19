#!/usr/bin/with-contenv bashio 
ssl=$(bashio::config 'ssl')
website_name=$(bashio::config 'website_name')
thermiq_user=$(bashio::config 'thermiq_user')
thermiq_licensekey=$(bashio::config 'thermiq_licensekey')
mariadb_user=$(bashio::config 'mariadb_user')
mariadb_pw=$(bashio::config 'mariadb_pw')
thermiq_init=$(bashio::config 'thermiq_init')
certfile=$(bashio::config 'certfile')
keyfile=$(bashio::config 'keyfile')
DocumentRoot=$(bashio::config 'document_root')
phpini=$(bashio::config 'php_ini')
username=$(bashio::config 'username')
password=$(bashio::config 'password')
default_conf=$(bashio::config 'default_conf')
default_ssl_conf=$(bashio::config 'default_ssl_conf')
webrootdocker=/var/www/localhost/htdocs/
phppath=/etc/php84/php.ini

if [ $phpini = "get_file" ]; then
	cp $phppath /share/apache2addon_php.ini
	echo "You have requestet a copy of the php.ini file. You will now find your copy at /share/apache2addon_php.ini"
	echo "Addon will now be stopped. Please remove the config option and change it to the name of your new config file (for example /share/php.ini)"
	exit 1
fi


rm -r $webrootdocker

if [ ! -d $DocumentRoot ]; then
	echo "You haven't put your website to $DocumentRoot"
	echo "A default website will now be used"
	mkdir $webrootdocker
	cp /index.html $webrootdocker
else
	#Create Shortcut to shared html folder
	ln -s $DocumentRoot /var/www/localhost/htdocs
fi

#Set rights to web folders and create user
if [ -d $DocumentRoot ]; then
	find $DocumentRoot -type d -exec chmod 771 {} \;
	if [ ! -z "$username" ] && [ ! -z "$password" ] && [ ! $username = "null" ] && [ ! $password = "null" ]; then
		adduser -S $username -G www-data
		echo "$username:$password" | chpasswd $username
		find $webrootdocker -type d -exec chown $username:www-data -R {} \;
		find $webrootdocker -type f -exec chown $username:www-data -R {} \;
	else
		echo "No username and/or password was provided. Skipping account set up."
	fi
fi

if [ $phpini != "default" ]; then
	if [ -f $phpini ]; then
		echo "Your custom php.ini at $phpini will be used."
		rm $phppath
		cp $phpini $phppath
	else
		echo "You have changed the php_ini variable, but the new file could not be found! Default php.ini file will be used instead."
	fi
fi

if [ $ssl = "true" ] && [ $default_conf = "default" ]; then
	echo "You have activated SSL. SSL Settings will be applied"
	if [ ! -f /ssl/$certfile ]; then
		echo "Cannot find certificate file $certfile"
		exit 1
	fi
	if [ ! -f /ssl/$keyfile ]; then
		echo "Cannot find certificate key file $keyfile"
		exit 1
	fi
	mkdir /etc/apache2/sites-enabled
	sed -i '/LoadModule rewrite_module/s/^#//g' /etc/apache2/httpd.conf
	echo "Listen 8099" >>/etc/apache2/httpd.conf
	echo "<VirtualHost *:80>" >/etc/apache2/sites-enabled/000-default.conf
	echo "ServerName $website_name" >>/etc/apache2/sites-enabled/000-default.conf
	echo "ServerAdmin webmaster@localhost" >>/etc/apache2/sites-enabled/000-default.conf
	echo "DocumentRoot $webrootdocker" >>/etc/apache2/sites-enabled/000-default.conf

	echo "#Redirect http to https" >>/etc/apache2/sites-enabled/000-default.conf
	echo "    RewriteEngine On" >>/etc/apache2/sites-enabled/000-default.conf
	echo "    RewriteCond %{HTTPS} off" >>/etc/apache2/sites-enabled/000-default.conf
	echo "    RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}" >>/etc/apache2/sites-enabled/000-default.conf
	echo "#End Redirect http to https" >>/etc/apache2/sites-enabled/000-default.conf

	echo "    ErrorLog /var/log/error.log" >>/etc/apache2/sites-enabled/000-default.conf
	echo "        #CustomLog /var/log/access.log combined" >>/etc/apache2/sites-enabled/000-default.conf
	echo "</VirtualHost>" >>/etc/apache2/sites-enabled/000-default.conf

	echo "<IfModule mod_ssl.c>" >/etc/apache2/sites-enabled/000-default-le-ssl.conf
	echo "<VirtualHost *:443>" >>/etc/apache2/sites-enabled/000-default-le-ssl.conf
	echo "ServerName $website_name" >>/etc/apache2/sites-enabled/000-default-le-ssl.conf
	echo "ServerAdmin webmaster@localhost" >>/etc/apache2/sites-enabled/000-default-le-ssl.conf
	echo "DocumentRoot $webrootdocker" >>/etc/apache2/sites-enabled/000-default-le-ssl.conf

	echo "    ErrorLog /var/log/error.log" >>/etc/apache2/sites-enabled/000-default-le-ssl.conf
	echo "        #CustomLog /var/log/access.log combined" >>/etc/apache2/sites-enabled/000-default-le-ssl.conf
	echo "SSLCertificateFile /ssl/$certfile" >>/etc/apache2/sites-enabled/000-default-le-ssl.conf
	echo "SSLCertificateKeyFile /ssl/$keyfile" >>/etc/apache2/sites-enabled/000-default-le-ssl.conf
	echo "</VirtualHost>" >>/etc/apache2/sites-enabled/000-default-le-ssl.conf
	echo "</IfModule>" >>/etc/apache2/sites-enabled/000-default-le-ssl.conf
else
	echo "SSL is deactivated and/or you are using a custom config."
fi
if [ "$ssl" = "true" ] || [ "$default_conf" != "default" ]; then
	echo "Include /etc/apache2/sites-enabled/*.conf" >>/etc/apache2/httpd.conf
fi

sed -i -e '/AllowOverride/s/None/All/' /etc/apache2/httpd.conf

if [ "$default_conf" = "get_config" ]; then
	if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then
		if [ ! -d /etc/apache2/sites-enabled ]; then
			mkdir /etc/apache2/sites-enabled
		fi
		cp /etc/apache2/sites-enabled/000-default.conf /share/000-default.conf
		echo "You have requested a copy of the apache2 config. You can now find it at /share/000-default.conf ."
	fi
	if [ -f /etc/apache2/httpd.conf ]; then
		cp /etc/apache2/httpd.conf /share/httpd.conf
		echo "You have requested a copy of the apache2 config. You can now find it at /share/httpd.conf ."
	fi
	if [ "$default_ssl_conf" != "get_config" ]; then
		echo "Exiting now..."
		exit 0
	fi
fi

if [[ ! $default_conf =~ ^(default|get_config)$ ]]; then
	if [ -f $default_conf ]; then
		if [ ! -d /etc/apache2/sites-enabled ]; then
			mkdir /etc/apache2/sites-enabled
		fi
		if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then
			rm /etc/apache2/sites-enabled/000-default.conf
		fi
		cp -rf $default_conf /etc/apache2/sites-enabled/000-default.conf
		echo "Your custom apache config at $default_conf will be used."
	else
		echo "Cant find your custom 000-default.conf file $default_conf - be sure you have chosen the full path. Exiting now..."
		exit 1
	fi
fi

if [ "$default_ssl_conf" = "get_config" ]; then
	if [ -f /etc/apache2/httpd.conf ]; then
		cp /etc/apache2/sites-enabled/000-default-le-ssl.conf /share/000-default-le-ssl.conf
		echo "You have requested a copy of the apache2 ssl config. You can now find it at /share/000-default-le-ssl.conf ."
	fi
	echo "Exiting now..."
	exit 0
fi

if [ "$default_ssl_conf" != "default" ]; then
	if [ -f $default_ssl_conf ]; then
		if [ ! -d /etc/apache2/sites-enabled ]; then
			mkdir /etc/apache2/sites-enabled
		fi
		if [ -f /etc/apache2/sites-enabled/000-default-le-ssl.conf ]; then
			rm /etc/apache2/sites-enabled/000-default-le-ssl.conf
		fi
		cp -rf $default_ssl_conf /etc/apache2/sites-enabled/000-default-le-ssl.conf
		echo "Your custom apache config at $default_ssl_conf will be used."
	else
		echo "Cant find your custom 000-default-le-ssl.conf file $default_ssl_conf - be sure you have chosen the full path. Exiting now..."
		exit 1
	fi
fi

mkdir -p /usr/lib/php84/modules/opcache

# Here goeas thermiq install,
if [ "$thermiq_init" == "true" ]; then
	echo "Installing ThermIQ from web"
	cd /tmp/thermiq_install
	rm -rf *

	curl -o thermiq2_instal.tar.gz "http://www.thermiq.net/getThermIQ2.php?base_install=haos" 
	tar xzf thermiq2_instal.tar.gz
	cp -f pkg_haos/php_haos.ini /share/php.ini
	
	chmod ug+x usr/sbin/*
	hashue=`php84 usr/sbin/hashit $thermiq_user`
	hashpw=`php84 usr/sbin/hashit -c $thermiq_licensekey`

	curl "https://www.thermiq.net/getThermIQ2.php?USERID=${hashue}&USERKEY=${hashpw}&USERMODULES=all" | jq -r .[][0] | while read -r module; \
       do curl -o "$module.tar.gz" https://www.thermiq.net/getThermIQ2.php -H "Accept: application/json" -H "USERID: ${hashue}" -H "USERKEY: ${hashpw}" -H "USERDLREV: beta" -H "USERMODULE: $module" -H "USERVERSION: 1" -H "USEROS: Linux" -H "MACHINEID: 1234"; tar xvf $module.tar.gz; \
    done;

	chmod ug+x usr/sbin/*
	cp -rf usr/sbin/* /share/thermiq/
	cp -rf html/* /share/htdocs/
	chmod -R ug+r /share/htdocs/*
	rm -f /share/htdocs/index.html

	if [ -e /share/thermiq/etc/Thermiq_Haos.ini ]; then cp -f /share/thermiq/etc/Thermiq_Haos.ini /tmp/thermiq_install/opt/etc/;else \
		cd opt/etc/
		sed -i "s:mysql_users_user.*:mysql_users_user = '${mariadb_user}':" Thermiq_Haos.ini
		sed -i "s:mysql_users_pw.*:mysql_users_pw = '${mariadb_pw}':" Thermiq_Haos.ini
		sed -i "s:mysql_thermiq_user.*:mysql_thermiq_user = '${mariadb_user}':" Thermiq_Haos.ini
		sed -i "s:mysql_thermiq_pw.*:mysql_thermiq_pw = '${mariadb_pw}':" Thermiq_Haos.ini


		sed -i 's:\[thermiq\]::' Thermiq_Haos.ini
		sed -i 's:order_email.*::' Thermiq_Haos.ini
		sed -i 's:license_key.*::' Thermiq_Haos.ini
		echo "[thermiq]" >> Thermiq_Haos.ini
		echo "order_email=${thermiq_user}" >> Thermiq_Haos.ini
		echo "license_key=${thermiq_licensekey}" >> Thermiq_Haos.ini
		php84 /share/thermiq/mkdbtemplate -m ThermIQ ThermIQ_MQTT
	fi
	cp -rf /tmp/thermiq_install/opt/etc/* /share/thermiq/etc/
	chmod a+rw /opt/etc/*

	# ThermIQ_Haos.ini


	cd /tmp
	#rm -rf thermiq_install
fi

#php84 /share/thermiq/ThermIQ_MQTT_listener &




#php84 usr/sbin/mkdbtemplate -m ThermIQ ThermIQ_MQTT

#rm -rf /tmp/thermiq_install


echo "Here is your web file architecture."
ls -l $webrootdocker

echo "Starting Apache2..."
exec /usr/sbin/httpd -D FOREGROUND
