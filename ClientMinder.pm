package ClientMinder;
# This package models a ClientMinder, from the ServerMinder's point of view. 
use strict;
use warnings;

use Class::Tiny qw(
    IPaddress
    Port
    RecentStamp 
    Wakeup      
    ),
 { 

 }
;


my %clients;



sub  wakeup {
    # Look at all the clients. If they need attention, give it.
    # If they don't, then tell when they next need it.
    my  $now = time();
    my  $first_wakeup = 8; # A default, maximum wait.

    return $first_wakeup;
    }

sub find_client {
    my $address= shift;
    if ( exists $clients{$address} ) {
        my %client = {$clients{$address}};
        my $theport = $client{port};
        print "Found the client for $address and Looks like port or $client{port} is will be  $client{$address}{address} \n";
        return $clients{$address};
    } else {
        print "New client with address $address";
        $clients{$address}{port} = 17;
        $clients{$address}{address} = $address;
        return $clients{$address};
    }
}

sub subscribe {
    my $address = shift;
    
    my $client = find_client($address);
    #print "And the address is $client{address} \n";
    my $answer = ${$client}{port};
    print "The port is $answer ! \n";

}

1;
