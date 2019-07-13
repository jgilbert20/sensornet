#!/usr/bin/perl


# Install:
# sudo cpan install Net::MQTT::Simple



use Net::MQTT::Simple;


my $mqtt = Net::MQTT::Simple->new("sensornet.local");

while (1) {

    open FILE, "/run/sensors/scd30/last" or die "Cannot open: $!";


    my ($var, $val );
    ($var, $val )= split /\s+/, <FILE>;
    my $co2 = $val;
    ($var, $val )= split /\s+/, <FILE>;
    my $temp = $val;
    ($var, $val )= split /\s+/, <FILE>;
    my $rh = $val;
    
    print "Co2,temp/rh = $co2 $temp $rh\n";
    
    $mqtt->publish("Sensornet/SCD30/SCD30/CO2/ppm" => $co2);
    $mqtt->publish("Sensornet/SCD30/SCD30/Temp-F/F" => $temp * 9/5 + 32);
    $mqtt->publish("Sensornet/SCD30/SCD30/RH/pct" => $rh);

    close FILE or die "Could note close $!";


    sleep 2;
}


