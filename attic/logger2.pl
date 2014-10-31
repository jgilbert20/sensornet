#!/usr/bin/perl
use strict;
use warnings;
use Device::SerialPort;

local $| = 1;

use POSIX qw(strftime);


use Device::SerialPort qw( :PARAM :STAT 0.07 );

my $PORT = "/dev/ttyAMA0";

my $ob = Device::SerialPort->new($PORT)  || die "Can't open $PORT: $!\n";
$ob->baudrate(57600);
$ob->write_settings;

open(PORT, "+>$PORT") or die "Cabnot open port $PORT";

my $needsHeader = 1 if ! -e "mainlog.csv";

open( LOGFILE, ">>spare.csv" );

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
