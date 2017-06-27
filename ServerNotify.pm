package ServerNotify;
# This is the correspondent in the Server, that talks to the Arbitrator.

# Outbound Messages:
# db_status_report, and this message will suffice for a hello
# Inbound messages
# status_request - should be replied with a poll, and a status report
# make_primary

use strict;
use warnings;
use parent 'Correspondent';
use Class::Tiny qw(
  status_group
  server
),
{
}
;

my $singleton;

sub BUILD {
    my $self=shift;
    $singleton = $self;
    $self->{peer_type}    ='Notify';
    $self->{peer_id} = 0;
    $self->{address} ='127.0.0.1';
    $self->{port}    =3309;
}

sub receive {
    my $self = shift;
    my @parms = shift;
    my $verb = shift @parms;
    print "Message is $verb from $self->{address}\n";
    if ($verb eq 'wsrep_notifty_cmd') {
	print "VERB is wsrep_notify_cmd\n";
	GaleraServer->wsrep_notify_cmd(@parms);
    }
}

1;

