sensornet
=========


Arduino sensor library


Install
-------

	cd /home/pi
	git clone <...> 
	cd sensornet
	sudo cpan Device::SerialPort
	sudo cp sensornet.init /etc/init.d/sensornet
	sudo chmod 755 /etc/init.d/sensornet

You may want to point your web server at www

    4c4
    <     DocumentRoot /var/www
    ---
    >     DocumentRoot /home/pi/sensornet/www
    9c9
    <     <Directory /var/www/>
    ---
    >     <Directory /home/pi/sensornet/www>


Auto at startup
---------------

Enable:

	sudo update-rc.d sensornet defaults 99

Disable:

	sudo update-rc.d -f sensornet remove
