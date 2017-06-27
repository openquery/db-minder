package ArbitratorServer;
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
    $self->{peer_type}='Server';
}


sub receive {
    my $self = shift;
    my @parms = @{$_[0]};
    my $verb = shift @parms;
    # print "Message is $verb from $self->{address}\n";
    if ($verb eq 'db_status_report') {
	$self->db_status_report(\@parms);
    }
}

sub db_status_report {
    my $self=shift;
    my @parms = @{$_[0]};
    $self->send("ack");
    my $wsrep_cluster_name = shift @parms;
    print "Cluster name is $wsrep_cluster_name \n";
    my $wsrep_node_name = shift @parms;
    print "Node name is $wsrep_node_name \n";
    $self->{status_running} = shift @parms;
    $self->{status_serving} = shift @parms;
    $self->{status_primary} = shift @parms;
    $self->{status_group}   = shift @parms;
    print "We heard from peer_id $self->{peer_id}\n";
    GaleraArbitrator::db_status_report($self->{peer_id},$self->{status_group},$self->{status_primary});
}



1;

