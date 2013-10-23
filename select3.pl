#!/usr/bin/perl

# To install
# cpan install YAML
# DBD::Pg
# export PATH=$PATH:/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:/Applications/Xcode.app/Contents/Developer/usr/bin/

# http://www.felixgers.de/teaching/perl/perl_DBI.html

use strict;
use warnings;


$| = 0;

my $timeout = 1;

use POSIX qw(strftime);
use IO::Select;
use IO::Socket; use IO::File;
use IO::Handle;

my $needsHeader = 1 if ! -e "mainlog.csv";

my $tty = IO::Handle->new();

if( 1 )
{

    use Device::SerialPort;

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

    open( $tty, "/dev/ttyAMA0" ) or die "Cannot open tty";
}
else
{
    sysopen( $tty , "neep", O_RDWR) or die "Sysopen failed";    
}

open( LOGFILE, ">>mainlog-test.csv" );

if( $needsHeader )
{
	print LOGFILE "TS,Sequence,Node,Millis,Sensor,Reading,ReadingUnits,Memo,RSSI,OriginId\n";
}


my $lsn = IO::Socket::INET->new(Listen => 1, LocalPort => 8080) or die "Cannot bind";
my $sel = IO::Select->new( $lsn );
$sel->add( $tty );



my $DB_user    = 'postgres';
my $DB_name    = 'sensor';
my $DB_pwd     = '';

my %taskRegistry;
sub debug
{
	my @arg = @_;

	print STDERR "DEBUG: ";
	print STDERR @arg;
	print STDERR "\n";
}

#$dbh = DBI->connect("dbi:Pg:dbname=$DB_name","$DB_user","$DB_pwd");


registerTask( "dumpps", 50, sub { `mkdir -p pslog`; `ps > pslog/foo.txt` } );

sub registerTask
{
	my $tName = shift;
	my $interval = shift;
	my $code = shift;

	$taskRegistry{$tName} = [$interval, 0, $code];
}

sub runScheduledTasks
{
	debug "Housekeeping -- Event recv";	

	foreach my $n (keys %taskRegistry)
	{
		my $t = $taskRegistry{$n};
	
		debug( "Checking task $n -> @$t");
		if( time() - $t->[1] >  $t->[0] )
		{		
			debug( "Task $t has come due..");

			$t->[1] = time();
		}

	}


}


my %runStats;



while(1)
{
    while(my @ready = $sel->can_read( $timeout )) 
    {
	foreach my $fh (@ready) 
	{
	    if($fh == $lsn) 
	    {
                # Create a new socket
                my $new = $lsn->accept;
                $sel->add($new);
                print STDOUT "Accepted new connection from XXX\n";
                syswrite( $new, "Welcome to SensorMonitor");
            }
            elsif( $fh == $tty )
            {	
            	my $in;		
            	my $b = sysread( $fh, $in, 1000);
            	$runStats{"TTY_BYTES_READ"} += $b;  
            	handleTTYDataPacket( $in );	
            }
            else {
                # Process socket
                # Maybe we have finished with the socket
                my $in;
                sysread( $fh, $in, 1000);

                debug "Got data from socket: [$in]";

                syswrite( $fh, "Bye");
                $sel->remove($fh);
                $fh->close;
            }
        }
    }
    
    runScheduledTasks();
}

my $ttyBuffer = "";

#use IO::Scalar;
# $TTY_INTERNAL = new IO::Scalar \$ttyBuffer;

sub handleTTYLine
{
	my $line = shift;

	my $date = strftime("%Y-%m-%d %H:%M:%S", localtime(time));

	$runStats{"TTY_MSG_READ"} += 1;  

	debug( "Received LINE: [$line]");
    my @a = split( ',', $line);

	my $fCount= 0 + @a;
    if( $fCount != 9 	)
    {	
		print "Error - [$fCount] wrong number of commas, skipping\n";
		$runStats{"TTY_MSG_READ_ERROR"} += 1; 
		next;	
    }

    $runStats{"TTY_MSG_READ_GOOD"} += 1; 

	my ( $sequence, $node,	$millis, $sensor, $reading, $readingUnits, $memo, $RSSI, $originId ) = @a;

	$runStats{"NODE_$(node)_MSG_CNT"} += 1; 

	my $date = strftime("%Y-%m-%d %H:%M:%S", localtime(time));

	print LOGFILE "$date,$line\n";

	flush LOGFILE; 
}

sub  handleTTYDataPacket
{
	my $data = shift;

	# debug( "Adding to TTY buffer:[$data]");
	$ttyBuffer .= $data;

	while( (my $nextNL = index( $ttyBuffer, "\n",0 )) != -1 )
	{
		debug "Newine detected at position [$nextNL]"; # in [$ttyBuffer]";
		my $nextline = substr( $ttyBuffer, 0, $nextNL + 1 );
		substr( $ttyBuffer, 0, $nextNL + 1, "" );
		chomp $nextline;

		handleTTYLine( $nextline ) if( length $nextline > 0 );
	}
}

END: 
{
	debug "Shutting down...";
	$lsn->close();
} 
