#!/usr/bin/with-contenv bashio 
ssl=$(bashio::config 'ssl')
phpini=$(bashio::config 'php_ini')
phppath=/etc/php84/php.ini

if [ $phpini = "get_file" ]; then
	cp $phppath /share/apache2addon_php.ini
	echo "You have requestet a copy of the php.ini file. You will now find your copy at /share/apache2addon_php.ini"
	echo "Addon will now be stopped. Please remove the config option and change it to the name of your new config file (for example /share/php.ini)"
	exit 1
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
else
	echo "SSL is deactivated and/or you are using a custom config."
fi



mkdir -p /usr/lib/php84/modules/opcache

#rm -rf /tmp/thermiq_install


echo "Here is your web file architecture."
ls -l $webrootdocker

echo "Starting ThermIQ_MQTT_listener..."
exec php84 /share/thermiq/ThermIQ_MQTT_listener 
