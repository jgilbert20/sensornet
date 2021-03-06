#!/usr/bin/env python3

# Lovely - this only works in python 3'


# mosquitto_pub -h sensornet.local -t "DMX/008" -m "100"
from array import *

import sys, traceback
import re
import paho.mqtt.client as mqtt
import datetime
import time
from DMXEnttecPro import Controller

dmx = Controller('/dev/ttyUSB0')

def on_connect(client, userdata, rc, sparearg):
    print("Connected with result code "+str(rc))
    client.subscribe("DMX/#")

def num(s):
    try:
        return int(s)
    except ValueError:
        return float(s)


levels = array( 'L', [128] * 255 );
    
def on_message(client, userdata, msg):
    try:
        print( "msg recv" )
        # Use utc as timestamp
        receiveTime=datetime.datetime.utcnow()
        message=msg.payload.decode("utf-8")
        tmp=msg.topic

        print( "Received topic=" + msg.topic + " payload=" + message )

        args=re.split( "/", tmp );
        channel=args[1]
        operation=args[2]
        chnum=int(channel)
        
        print( "      Channel:" + str(chnum) + "   operation:" + operation );
        

        if( operation == "brightness" ):
            level=num(message)
            print( "      Brightness: ch=" + str(chnum) + " -> " + str(level) )
            dmx.set_channel(int(channel), int(level))
            dmx.submit()
            levels[chnum]=int(level)


        if( operation == "set" ):
            print( "      Setting: ch=" + str(chnum) + " -> " + str(message) )
                        
            if( message == "on" or message == "true" ):
                dmx.set_channel(int(channel), int(levels[int(channel)]))
            else:
                dmx.set_channel(int(channel), 0 )
            dmx.submit()




            
    except:
        print ("Exception in user code:")
        print ('-'*60)
        traceback.print_exc(file=sys.stdout)
        print ('-'*60)

    
    
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

print("All setup, starting main loop")
    
# Blocking loop to the Mosquitto broker
client.loop_forever()
