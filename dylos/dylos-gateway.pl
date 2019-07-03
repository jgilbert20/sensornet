#!/usr/bin/perl

# Every minute the Dylos emits PPM data at 9600 baud
# This script sits in a loop, reading this data and transmits it to an MQTT server


# Install:
# sudo cpan install Device::SerialPort Net::MQTT::Simple


use Device::SerialPort qw( :PARAM :STAT 0.07 );
use Net::MQTT::Simple;


my $mqtt = Net::MQTT::Simple->new("sensornet.local");


my $port=Device::SerialPort->new("/dev/ttyS0");

my $STALL_DEFAULT=100; # how many seconds to wait for new input

my $timeout=$STALL_DEFAULT;

$port->read_char_time(0);     # don't wait for each character
$port->read_const_time(1000); # 1 second per unfulfilled "read" call

my $chars=0;
my $buffer="";
while (1) {
    my ($count,$saw)=$port->read(255); # will read _up to_ 255 chars
    if ($count > 0) {
	$chars+=$count;
	$buffer.=$saw;
	
	
	chomp $buffer;
	
	print "Read from dylos: $buffer\n";
	
	my ($a, $b) = split ",", $buffer;
	
	$mqtt->publish("Sensornet/Dylos/Dylos/PPM0.5/ppm" => $a);
	$mqtt->publish("Sensornet/Dylos/Dylos/PPM2.5/ppm" => $b);
	
	$buffer = "";
	
	# Check here to see if what we want is in the $buffer
	# say "last" if we find it
    }
    else {
	$timeout--;
    }    
}


