sensornet
=========

Arduino sensor library


Install
-------

	sudo cp sensornet.init /etc/init.d/sensornet
	sudo chmod 755 /etc/init.d/sensornet

Auto at startup
---------------

	sudo update-rc.d sensornet defaults 99
	sudo update-rc.d -f sensornet remove
