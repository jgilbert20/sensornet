#!/usr/bin/perl

use threads;
use strict;

use Time::HiRes qw(gettimeofday);
use Date::Parse;

use POSIX qw(strftime);
use IO::Select;
use IO::Socket; 
use IO::File;
use IO::Handle;

my $BASEDIR = ".";

my $LOGFN = "$BASEDIR/mainlog.csv";
my $DEBUGFN = "$BASEDIR/streamlog.txt";
my $PGSPOOL = "$BASEDIR/pgspool.csv";

open( DEBUGFILE, ">>$DEBUGFN" ) or die "Cannot open debug log";

sub debug
{
	my @arg = @_;

	my ($s,$ms) =
	    gettimeofday();
	
	my $ts = localtime( $s ) ;
		
	my	$str = POSIX::strftime( "%Y/%m/%d %H:%M:%S", localtime $s );

	print STDERR "$str.$ms: ";
	print STDERR @arg;
	print STDERR "\n";

	print DEBUGFILE "$str.$ms: ";
	print DEBUGFILE @arg;
	print DEBUGFILE "\n";
	
	DEBUGFILE->flush();
}

debug( "Starting up...");

my %nodeLastHeard;
my %nodeDataHistories;

open INDATA, "<$LOGFN" or die "Cannot open $LOGFN";
open PGTMP, ">$PGSPOOL" or die "Cannot open temp file";
#binmode(INDATA);

my $pgSpooledLines = 0;

my $lastSentToPostgres = 0;
my $lastRsync = 0;
my $lastWWW = 0;

while( <INDATA> )
{
	my $curLine = $_;


	chomp $curLine;
	chomp $curLine;
	$curLine =~ s/[\r\n]+\Z//;

	# $curline =~ s/\r|\n|\m|\f|\l|\cm|\m]+/T/gi;
	#$curline =~ tr/\015//d;
	#$curline =~ s/\r*//gm;
  #	$curline =~ s/\r?//gm;

	
	
	my $res = my( $ts, $seq, $node, $millis,$sensor,$reading,$units,$memo,$rssi,$originId) = (split /,/, $curLine);
	if( $res != 10 )
	{
		debug "Short line? $curLine";
		next;
	}	

	# attempt to detect header lines
	next if $ts eq 'TS';

	# Skip C readings -- the gateway will have converted these to F already
	next if $units eq 'C';



	next unless $node eq 'Mote2' and $sensor eq 'Dallas-F';

	debug( "Read: $curLine");

	$nodeLastHeard{$node} = str2time($ts);
	push @{$nodeDataHistories{"$node:$sensor"}}, [$ts, $reading];
	if( 0 + @{$nodeDataHistories{"$node:$sensor"}} > 100 )
	{
		shift @{$nodeDataHistories{"$node:$sensor"}};
	}

	print PGTMP "$curLine\n";
	$pgSpooledLines++;
	
	if( time() - $lastSentToPostgres > 5 )
	{
		sendSpoolToPG();
	}

	if( time() - $lastWWW > 5 )
	{
		generateWWW();
		$lastWWW = time();
	}



	# Rsync really isn't a good thing to add in here, much better as a cron job..

	if( 0 && time() - $lastRsync > 1000 )
	{
				debug( "Starting rsync to auspice");

		my $hn = `hostname`;
		chomp $hn;
		`rsync $LOGFN jgilbert\@www.auspice.net:mainlog-$hn.csv`;

				debug( "Rsync complete");



	}

	sleep(1);
}

# wrap up any last lines...
sendSpoolToPG();

sub generateWWW
{

	foreach my $i (keys %nodeDataHistories)
	{
		my( $node, $sensor ) = split /:/, $i; 

		my $total = 0;
		my $count = 0; 

		map { $count++; $total += $_->[1] } @{$nodeDataHistories{$i}};

		my $avg = $total / $count; 
		my $howLongHasItBeen =  time() - $nodeLastHeard{$node}; 

		my $timeSince;

		if( $howLongHasItBeen > 24*60*60 )
		{
			my $r = $howLongHasItBeen / (24*60*60);
			$r = sprintf( "%.1f", $r); 
			$timeSince = "$r days"

		}
		else
		{
		my $r = $howLongHasItBeen / (60); 
		$r = sprintf( "%.1f", $r);
			$timeSince = "$r minutes"

		}

		debug "$i --> Total = $total / $count = $avg - last $timeSince ($howLongHasItBeen - $nodeLastHeard{$node})";




	}	

	return;
}


sub sendSpoolToPG
{

		debug( "Starting spool to postgres... [$pgSpooledLines] lines pending");
		close PGTMP;

		`cat $PGSPOOL | psql sensornet -c 'copy raw_sensor_data from STDIN csv'`;
		$lastSentToPostgres = time();
		debug( "Transfer completed");
		open PGTMP, ">$PGSPOOL" or die "Cannot open temp file";

		$pgSpooledLines = 0;

}

my $C = <<FOO;

	CREATE TABLE raw_sensor_data
	(
		ts timestamp without time zone not null,
		sequence varchar,
		node varchar,
		millis varchar,		
		sensor varchar,
		reading float,				
		units varchar,
	    memo varchar,
	    rssi integer,
	    originID integer
		);
FOO







