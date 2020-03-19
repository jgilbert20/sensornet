use Device::SerialPort;
use GD;
use Time::HiRes qw(usleep nanosleep);

use strict;

# For Epson TM-220 presumably

# sudo apt-get install  libdevice-serialport-perl imagemagick libtemplate-plugin-gd-perl

## Using the stupid IOgear GURS232 thingy
## if the buffer is overflowed, a full CPU restart may be needed to clear the driver
## also helps sometimes to install the IoGear driver even if it sometimes works without one..
## lots of flakiness abounds. 
## If in doubt, restart!

## this version is intended to direct serial
## note: gender changer has to be right


my $SOURCENAME = $ARGV[0];
system("convert -trim -resize 200 -monochrome $SOURCENAME /tmp/foo.png");

my $im = GD::Image->new('/tmp/foo.png');

# my $im = GD::Image->new(150,100);
#     my $white = $im->colorAllocate(255,255,255);
#     my $black = $im->colorAllocate(0,0,0);

#     # Put a black frame around the picture
#     $im->rectangle(0,0,149,99,$black);
#         # Draw a blue oval
#     $im->arc(50,50,95,75,0,360,$black);

# $im->string(gdSmallFont,2,10,"Peachy Keen",$black);

# make sure we are writing to a binary stream
binmode STDOUT;

# Convert the image to PNG and print it on standard output
open PNG, ">debug-$$.png" or die "";
print PNG $im->png;
close PNG;

my( $w, $h ) = $im->getBounds;

my $xSize = $w;
my $ySize = $h;
my $xpos;
my $ypos;

my $buffer = "";

my $totalRows = $ySize / 8 + ( $ySize % 8 > 0 ? 1 : 0 );

for( my $row = 0; $row < $totalRows; $row++ )
{



    # writeBytes(ASCII_ESC, 'U', 1);

    # writeBytes(ASCII_ESC, '3', 15);

    # unidirectional mode ON
    $buffer .= chr(27);
    $buffer .= 'U';
    $buffer .= chr(1);



    $buffer .= chr(27);
    $buffer .= '3';
    $buffer .= chr(15);

    $buffer .= chr(10);
    $buffer .= chr(13);
    $buffer .= chr(27);
    $buffer .= '*';
    $buffer .= chr(0);
    $buffer .= chr($xSize);
    $buffer .= chr(0);

    for( my $col = 0; $col < $xSize; $col++ )
    {
        my $v = 0;
        for( my $p = 0; $p < 8; $p++ )
        {

            my $y     = $row * 8 + $p;
            my $x     = $col;
            my $pixel = $im->getPixel( $x, $y );
            my $exponent;

            my( $r, $g, $b ) = $im->rgb($pixel);

            my $dothere = 0;
            if( $r < 127 )
            {
                $dothere = 1;

            }
            if( $dothere == 1 )
            {
                $exponent = 2**( 7 - $p );
                $v        = $v + $exponent;

            }

            print
                "Row=$row col=$col x=$x y=$y p=$p pix=$pixel exp=$exponent v=$v RGB($r,$g,$b) DotHere:$dothere\n";

        }
        print "Writing byte: $v\n";
        $buffer .= chr($v);


      
    }
      $buffer .= "";
}

sub hdump
{
    my $offset = 0;
    my( @array, $format );
    foreach
        my $data ( unpack( "a16" x ( length( $_[0] ) / 16 ) . "a*", $_[0] ) )
    {
        my($len) = length($data);
        if( $len == 16 )
        {
            @array = unpack( 'N4', $data );
            $format = "0x%08x (%05d)   %08x %08x %08x %08x   %s\n";
        }
        else
        {
            @array = unpack( 'C*', $data );
            $_ = sprintf "%2.2x", $_ for @array;
            push( @array, '  ' ) while $len++ < 16;
            $format = "0x%08x (%05d)"
                . "   %s%s%s%s %s%s%s%s %s%s%s%s %s%s%s%s   %s\n";
        }
        $data =~ tr/\0-\37\177-\377/./;
        printf $format, $offset, $offset, @array, $data;
        $offset += 16;
    }
}

hdump($buffer);

# exit;

# $im->getPixel(20,100);

# http://search.cpan.org/~lds/GD-2.11/GD.pm

use Symbol qw( gensym );
my $PORT = "/dev/ttyUSB0";
    # "/dev/tty.usbserial-AI02CU1B";

#    $tty = gensym();
#    my $ob = tie( *$tty, "Device::SerialPort", $PORT );

my $port = Device::SerialPort->new($PORT);

#        $port->read_char_time(0);     # don't wait for each character
#        $port->read_const_time(0); # 1 second per unfulfilled "read" call
$port->baudrate(9600);
        $port->read_char_time(0);     # don't wait for each character
        $port->read_const_time(5); # 1 second per unfulfilled "read" call

$port->parity("none");
$port->databits(8);
$port->stopbits(1);        # POSIX does not support 1.5 stopbits

$port->dtr_active(1);



# my $milliseconds = 200;

#          $port->pulse_break_on($milliseconds); # off version is implausible
#          $port->pulse_rts_on($milliseconds);
#          $port->pulse_rts_off($milliseconds);
#          $port->pulse_dtr_on($milliseconds);
#          $port->pulse_dtr_off($milliseconds);



         # if ($port->can_wait_modemlines) {
         #   my $rc = $port->wait_modemlines( $port->MS_RLSD_ON );
         #   if (!$rc) { print "carrier detect changed\n"; }
         # }

         # if ($port->can_modemlines) {
         #    my $ModemStatus = $port->modemlines;
         #   if ($ModemStatus & $port->MS_RLSD_ON) { print "carrier detected\n"; }
         # }


# $ob->write_settings;

# debug( "Opening port" );
$port->write( chr(27) );
$port->write( '@' );



# # reverse 2 lines, doens't work..?
# $port->write( chr(27) );
# $port->write( 'e' );
# $port->write( chr(2) );

if( 0 )
{
# reverse 2 lines, but sometimes cauess print quality issues..
$port->write( chr(27) );
$port->write( 'K' );
$port->write( chr(48) );
$port->write( "\r\n");
}

$port->write("A fun picture for Isabella\r\n");

$port->write( chr(27) );
$port->write( '@' );

$port->write("$SOURCENAME\r\n");

$port->write( chr(27) );
$port->write( '@' );

for( my $i = 0 ; $i < 15 ; $i++)
{
$buffer .= "\r\n";
}

# executes a cut sheet, i = 1 point, m = 3 point
$buffer .= chr(27);
$buffer .= 'm';
$buffer .= "\r\n";


# while(1){}

# $port->purge_all();


#exit(0);

# $port->write( chr(27) );
# $port->write( '@' );

my $bytes = 0;

my @data = split //, $buffer;
my $totalSize = (scalar @data)+0;

print "Bytes to send: $totalSize\n"; 

while($bytes < $totalSize )
{



    for( my $r = 0; $r < 20; $r++ )
   {
usleep(1000);
        my $d = shift @data;
        my $x = ord( $d );

        # print "Sending: '$d' ($x)\n";

        if( defined $d )
        {
            my $retval = $port->write($d);
            my $exp = length($d);
            
            if( $retval != $exp )
            {
                print "Warning $retval != $exp - very likely will cause instability with iogear USB\n" if $retval != $exp;
                
                unshift @data, $d;
            }
            else
            {   
              $bytes++;
              
            }


        }
     
      

#        $port->purge_all();

    }
#sleep 1;

}



# while(1){}

$port->close();


print "Done\n";
