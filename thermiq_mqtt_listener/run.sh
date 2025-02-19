#!/usr/bin/with-contenv bashio 
phpini=$(bashio::config 'php_ini')
phppath=/etc/php84/php.ini

# ssl=$(bashio::config 'ssl')
# certfile=$(bashio::config 'certfile')
# keyfile=$(bashio::config 'keyfile')


if [ $phpini != "default" ]; then
	if [ -f $phpini ]; then
		echo "Your custom php.ini at $phpini will be used."
		rm $phppath
		cp $phpini $phppath
	else
		echo "You have changed the php_ini variable, but the new file could not be found! Default php.ini file will be used instead."
	fi
fi

# if [ $ssl = "true" ]; then
# 	echo "You have activated SSL. SSL Settings will be applied"
# 	if [ ! -f /ssl/$certfile ]; then
# 		echo "Cannot find certificate file $certfile"
# 		exit 1
# 	fi
# 	if [ ! -f /ssl/$keyfile ]; then
# 		echo "Cannot find certificate key file $keyfile"
# 		exit 1
# 	fi
# else
# 	echo "SSL is deactivated and/or you are using a custom config."
# fi



mkdir -p /usr/lib/php84/modules/opcache

echo "Starting ThermIQ_MQTT_listener..."
exec php84 /share/thermiq/ThermIQ_MQTT_listener -p
