#!/bin/bash

serv1=sensornet-rpimonitor.service

rsync -raxc --info=name $serv1 /etc/systemd/system/

systemctl enable $serv1 && echo "systemctl enable $serv1 OK"
systemctl restart $serv1 && echo "systemctl restart $serv1 OK"
