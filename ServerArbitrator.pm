package ServerArbitrator;
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
    $self->{peer}=ClusterConfig::nodeByTypeId('Arbitrator',0);
#    $self->{peer_type}    ='Arbitrator';
#    $self->{peer_id} = 0;
    
#    $self->{address} ='127.0.0.1';
#    $self->{port}    =3309;
    $self->set_wakeup('db_status_report',30); # Will proabably get a "new_status" before that.
}

sub receive {
    my $self = shift;
    my @parms = @{$_[0]};
    my $verb = shift @parms;
    print "Message is $verb \n";
    if ($verb eq 'status_request') {
	print "VERB is status_request\n";
	$self->{server}->poll();
	$self->db_status_report();	
    }
    if ($verb eq 'make_primary') {
	print "Verb is make_primary";
	$self->{server}->make_primary(\@parms);
    }
    if ($verb eq 'request_status') {
	$self->db_status_report();
    }

    if ($verb eq 'OK') {
	print "Verb is OK\n";
	# No action for OK - we have recorded the timestamp of the message.
    }
}

sub db_status_report {
    my $self = shift;
    my $status = $self->{server}->get_status();
    $self->send("db_status_report $status",1);
    $self->set_wakeup('db_status_report',30);
}

sub wakeup {
    my $self = shift;
    # Send a status report once per 5 minutes
    print "ServerArbitrator is awake\n";
    $self->db_status_report();
}

sub new_status {
    $singleton->db_status_report;
}
1;

