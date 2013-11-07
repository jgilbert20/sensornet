#!/usr/bin/perl

my $firstline = <>;

my %fields; 

use Date::Parse;

my $lastLineDateCode;
my $valueInWindow = {};

my @reportsToIssue;

use strict;
while( <> )
{
	chomp;
	my @a = split /,/;


	my ( $ts, $sequence, $node,	$millis, $sensor, $reading, $readingUnits, $memo, $RSSI, $originId ) = @a;
 	my ( $ss,$mm,$hh,$day,$month,$year,$zone ) = strptime($ts);	

 	my $dateCode = "$year-$month-$day-$hh-$mm";

	my $f ="$node.$sensor";
	$fields{$f}++;
	$valueInWindow->{$f} = $reading;
$valueInWindow->{TS} = $ts;

 	if( $dateCode ne $lastLineDateCode) 
 	{
 		print STDERR "Processing: $ts\n";
 	#	print keys %$valueInWindow;
 		
 		push @reportsToIssue, $valueInWindow; 


 		 $valueInWindow = {};


 		$lastLineDateCode = $dateCode; 
 	}


#	print "$ts -> $dateCode $sensor\n";
}

my @reportingFields = ("TS", sort keys %fields );

print join ",", @reportingFields;
print "\n";

foreach my $r (@reportsToIssue)
{
	my $l = join ",", map {$r->{$_} } (@reportingFields);
	print $l;

print "\n";
}




