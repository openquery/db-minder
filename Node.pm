package Node;
# This package
use strict;
use warnings;

use parent 'Wakeup';
use Class::Tiny qw(
    ),
 { 

 }
;


my $singleton;

sub BUILD {
    $singleton = shift;
    print "Assigning singleton in Node.pm";
}

sub single {
    return $singleton;
}
1;
