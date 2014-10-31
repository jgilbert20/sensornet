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

open( PORT, ">/dev/ttyAMA0" );



while(1)
{

    print PORT "gwup\n";

    sleep(1);
}
