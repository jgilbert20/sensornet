#!/usr/bin/perl


# Install:
# sudo cpan install Net::MQTT::Simple



use Net::MQTT::Simple;


my $mqtt = Net::MQTT::Simple->new("sensornet.local");

my $h = `hostname`;
chomp $h;
my $host = $h;


while (1) {

    $pUptime = `/bin/cat /proc/uptime`;
    chomp $pUtime;
    my( $uptime, $idle ) = (split /\s+/, $pUptime);

    $loadavg = `/bin/cat /proc/loadavg`;
    chomp $loadavg;
    my( $instantLoad, $fiveMinLoad ) = (split /\s+/, $loadavg);

    $clock = `/usr/bin/vcgencmd measure_clock arm`;
    chomp $clock;
    $clock =~ s/^[^=]*=//;
    $clock /= 1_000_000;
    
    $temp = `/usr/bin/vcgencmd measure_temp`;
    chomp $temp;
    $temp =~ /\=([\d.]+)/;
    $temp = $1;
    #die $temp;
    
    $mqtt->publish("Sensornet/rpi-mon/$host/uptime/seconds" => $uptime );
    $mqtt->publish("Sensornet/rpi-mon/$host/idle/seconds" => $idle );
    $mqtt->publish("Sensornet/rpi-mon/$host/load/seconds" => $instantLoad );
    $mqtt->publish("Sensornet/rpi-mon/$host/clock/mhrz" => $clock );
    $mqtt->publish("Sensornet/rpi-mon/$host/Temp-C/C" => $temp );
    $mqtt->publish("Sensornet/rpi-mon/$host/Temp-F/F" => $temp * 9/5 + 32);




    
#    $mqtt->publish("Sensornet/rpi-mon/$host/load/abs" => $load );

    sleep 60;
}


