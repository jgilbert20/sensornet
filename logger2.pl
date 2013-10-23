#!/usr/bin/perl
use strict;
use warnings;
use Device::SerialPort;

local $| = 1;

use POSIX qw(strftime);

print "Setting serial port to desired baud rate..\n";

## Set up the serial port...
my $port = Device::SerialPort->new("/dev/ttyAMA0");
$port->baudrate(57600);
$port->databits(8);
$port->parity("none");
$port->stopbits(1);
$port->handshake("none");
$port->stty_icrnl(1);
$port->write_settings;

print "Opening port\n";

open( PORT, "/dev/ttyAMA0" );

my $needsHeader = 1 if ! -e "mainlog.csv";

open( LOGFILE, ">>mainlog.csv" );

if( $needsHeader )
{
print LOGFILE "TS,Sequence,Node,Millis,Sensor,ReadingUnits,Memo,RSSI,OriginId\n";
}

while(1)
{
    my $line = <PORT>;
    chomp $line;
	next unless length $line > 0; 
#	my $t = localtime();
	my $date = strftime("%Y-%m-%d %H:%M:%S", localtime(time));
    print "Read: $line\n";
    my @a = split( ',', $line);
   # substr $line, 0,1 = "";
my $fCount= 0+@a;
 
    if( $fCount != 9 )
    {
	print "Error - [$fCount] wrong number of commas, skipping\n";
	next;
    }

    flush LOGFILE;
    
	print LOGFILE "$date,$line\n";
}
