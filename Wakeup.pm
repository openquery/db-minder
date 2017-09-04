package Wakeup;
# This package is a standard way to manage a bunch of things that want to wakeup.
use strict;
use warnings;


use Class::Tiny qw(
    wakee_object
    wakee_method
    wakeup_time
    ),
 { 

 }
;

# An array of all the wakers.
my %wakers;



sub  wakethem {
    # Look at all the wakers. If they need attention, give it.
    # return the number of sleeping seconds till next wakeup.
    my  $now = time();
    my $first_wakeup = $now + 100000;  # A default, maximum wait.
    my $key;
    foreach $key (keys %wakers)
    {
	my $waker = $wakers{$key};
	#print "Considering $waker->{wakeup_time}\n";
	if ($waker->{wakeup_time} <= $now) {
	    # print "Waking with method = $waker->{wakee_method}\n";
	    $waker->{wakeup_time} = 0; # Signal to delete the waker
	    my $the_method=$waker->{wakee_method};
	    $waker->{wakee_object}->$the_method();
	}
    }
    # Note that wakeup_time might have changed for some of the wakers, so we run a fresh loop.
    foreach $key (keys %wakers)
    {
	my $waker = $wakers{$key};
	# print "Considering $waker->{wakeup_time}\n";
	if ($waker->{wakeup_time} == 0) {
	    # print "Deleting waker\n";
	    delete $wakers{$key};
	} else {
	    if ($waker->{wakeup_time} < $first_wakeup) {
		$first_wakeup = $waker->{wakeup_time};
	    }
	}
    }
    my $sleep =  $first_wakeup - $now;
    # print "sleep for  $sleep\n";
    return $sleep;
}

sub set_wakeup {
    my $wakee = shift;
    my $wakee_method = shift;
    my $key = "$wakee:$wakee_method";
    my $interval = shift;
    my $waker;
    if ($interval == -1) {
	# Delete the waker
	if (defined $wakers{$key}) {
	    delete $wakers{$key};
	}
    } else {
	if (defined $wakers{$key}) {
	    $waker = $wakers{$key};
	} else {
	    $waker = Wakeup->new();
	    $wakers{$key} = $waker;
	}
	$waker->{wakee_method} = $wakee_method;
	$waker->{wakee_object} = $wakee;
	$waker->{wakeup_time} = time() + $interval;
    }
    

}

1;

    
