#prep
sudo apt-get install mosquitto-clients



sudo systemctl enable sensornet-mqtt-log.service

sudo systemctl start sensornet-mqtt-log.service

# view logs
journalctl -u sensornet-mqtt-log


