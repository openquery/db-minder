package ServerCommand;
# This class runs on the Server node, to manage communications with the Command nodes.
# There will be an instance of this class for each Command node

use strict;
use warnings;
use parent 'Correspondent';
use Class::Tiny qw(
  status_group
),
{
}
;

sub BUILD {
    my $self = shift;
    $self->{peer_type}='Command';
}


sub receive {
    my $self = shift;
    my @parms = @{$_[0]};
    my $verb = shift @parms;
    # print "Message is $verb from $self->{address}\n";
    if ($verb eq 'request_status') {
	$self->db_status_report(\@parms);
    }
}

sub db_status_report {
    my $self = shift;
    my $status = GaleraServer->single()->get_status();
    $self->send("db_status_report $status",0);
}

1;

