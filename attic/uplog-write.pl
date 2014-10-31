#!/usr/bin/perl

while(1)
{
`date >> uplog.txt`;
`uptime >> uplog.txt`;
`vcgencmd measure_temp >> uplog.txt`;

sleep(10);
}
