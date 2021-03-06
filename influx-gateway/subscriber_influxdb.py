#!/usr/bin/env python3

# Found here: https://larsbergqvist.wordpress.com/2017/03/02/influxdb-and-grafana-for-sensor-time-series/

import paho.mqtt.client as mqtt
import datetime
import time
from influxdb import InfluxDBClient

def on_connect(client, userdata, rc, sparearg):
    print("Connected with result code "+str(rc))
    client.subscribe("Sensornet/#")

def on_message(client, userdata, msg):
    # Use utc as timestamp
    receiveTime=datetime.datetime.utcnow()
    message=msg.payload.decode("utf-8")
    isfloatValue=False
    try:
        # Convert the string to a float so that it is stored as a number and not a string in the database
        val = float(message)
        isfloatValue=True
    except:
        isfloatValue=False

    if isfloatValue:
        print(str(receiveTime) + ": " + msg.topic + " " + str(val))

        json_body = [
            {
                "measurement": msg.topic,
                "time": receiveTime,
                "fields": {
                    "value": val
                }
            }
        ]

        dbclient.write_points(json_body)

# Set up a client for InfluxDB
dbclient = InfluxDBClient('localhost', 8086, 'root', 'root', 'sensors')

# Initialize the MQTT client that should connect to the Mosquitto broker
client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message
connOK=False
while(connOK == False):
    try:
        client.connect('sensornet.local', 1883, 60)
        connOK = True
    except:
        connOK = False
    time.sleep(2)

print "All setup, starting main loop"
    
# Blocking loop to the Mosquitto broker
client.loop_forever()
