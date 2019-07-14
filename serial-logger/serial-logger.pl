#!/usr/bin/perl


# 
# This script sits in a loop, reading serial data, and dumping it into a file with a timestamp


# Install:
# sudo cpan install Device::SerialPort 


use Device::SerialPort qw( :PARAM :STAT 0.07 );

my $port=Device::SerialPort->new("/dev/ttyUSB0");
$port->baudrate(115200);

my $STALL_DEFAULT=100; # how many seconds to wait for new input

my $timeout=$STALL_DEFAULT;

$port->read_char_time(0);     # don't wait for each character
$port->read_const_time(1000); # 1 second per unfulfilled "read" call

my $chars=0;
my $buffer="";
while (1) {
    my ($count,$saw)=$port->read(10000); # will read _up to_ 255 chars

    for( my $i = 0 ; $i < $count ; $i++ )
    {
	$chars++;
	my $c = substr $saw, $i, 1;
	
	if( $c eq "\n" )
	{

	    use POSIX qw(strftime);
                my $now_string = strftime "%Y/%m/%d %H:%M:%S", localtime;

			    
	    print "$now_string: $buffer\n";
	    $buffer = "";
	}
	else
	{
	    $buffer .= $c;
	}
    }
}


