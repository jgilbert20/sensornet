#!/usr/bin/perl

use strict;

#Install:
# sudo cpan install Device::SerialPort Net::MQTT::Simple

use Device::SerialPort qw( :PARAM :STAT 0.07 );
my $port=Device::SerialPort->new("/dev/ttyUSB0");


$port->baudrate(9600);
$port->parity("none");
$port->databits(8);
$port->stopbits(1);        # POSIX does not support 1.5 stopbits

# DC1 = 0x11
# DC2 = 0x12
# ETX = 0x03
# STX = 0x02


sub ysend
{
    my $v = shift;
    $port->write( $v );
    $v =~ s/(.)/sprintf("%X",ord($1))/eg;
    print "---> [$v]\n";
}



ysend( "\x11\x00\x00\x00\x03");
readuntilend();
die;
yget();
ysend( "\x11\x00\x00\x00\x03");
yget();
ysend( "\x11\x00\x00\x00\x03");
yget();
ysend( "\x11\x00\x00\x00\x03");
yget();
ysend( "\x11\x00\x00\x00\x03");
yget();




#$port->write( "\x02\x00\x07\x0E\x07\x0F\x03");

#my( $buf, $c) = $port->read(10);
#print "Got: [$buf]\n";




#open FOO, ">foo.txt" or die;
#print FOO  "\x0207AC9\x03" ;
#close FOO;


sub hexify
{
    my $t = shift;
    $t =~ s/(.)/sprintf("%X ",ord($1))/eg;
    return $t;
}

#    substr EXPR,OFFSET,LENGTH,REPLACEMENT
#    substr EXPR,OFFSET,LENGTH
#    substr EXPR,OFFSET


sub readuntilend
{

    my $b;
        while (1) {
	    my ($count,$saw)=$port->read(255); # will read _up to_ 255 chars


	    if( $count > 0 )
	    {
		$b .= $saw;

		
my		$o =  $saw;
		$saw = hexify( $saw );
		print "<---- [$count]: [$saw] ($o)\n";


		my $preamble = substr $b, 0,6;
		my $len = substr $b, 7,2;
		my $config = substr $b, 9, 255;


		print "Preable: $preamble\n";
		print "Preable: $len\n";

		for( my $i = 0 ; $i < 16 ; $i++ )
		{
		    my $t = substr $b, ($i*16)+9, 16;
		    my $j = hexify( $t );
		    my $ip = $i *16;
		    print "$ip -> $j ($t) \n";
		}
		
	    }
}

}

sub yget
{


        my $STALL_DEFAULT=1; # how many seconds to wait for new input

        my $timeout=$STALL_DEFAULT;

        $port->read_char_time(0);     # don't wait for each character
        $port->read_const_time(1000); # 1 second per unfulfilled "read" call

        my $chars=0;
        my $buffer="";
        while ($timeout>0) {
               my ($count,$saw)=$port->read(255); # will read _up to_ 255 chars
               if ($count > 0) {
                       $chars+=$count;
                       $buffer.=$saw;

                       # Check here to see if what we want is in the $buffer
                       # say "last" if we find it
               }
               else {
                       $timeout--;
               }
        }

	# print "Chars: $chars - Buffer: [$buffer] \n";

	$buffer =~ s/(.)/sprintf("%X",ord($1))/eg;
	


	print "<--- c:[$chars] Hex: [$buffer]\n";

	
#        if ($timeout==0) {
#               die "Waited $STALL_DEFAULT seconds and never saw what I wanted\n";
#}


}
