package ServerClient;
# This is the correspondent in the Server, that talks to the Client.

# Outbound Messages:
# db_status_report, and this message will suffice for a hello
# Inbound messages
#   status_request - should be replied with a poll, and a status report

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


sub BUILD {
    my $self=shift;
    $self->{peer_type} = 'Client';
    $self->set_wakeup('db_status_report',5);
}

sub receive {
    my $self = shift;
    my @parms = @{$_[0]};
    my $verb = shift @parms;
    print "Message is $verb \n";
    if ($verb eq 'request_status') {
	$self->db_status_report();
    }
}

sub db_status_report {
    my $self = shift;
    my $status = GaleraServer->single()->get_status();
    $self->send("db_status_report $status",1);
    $self->set_wakeup('db_status_report',60);
}


sub new_status {
    
    # All peers: ->db_status_report;
}
1;

