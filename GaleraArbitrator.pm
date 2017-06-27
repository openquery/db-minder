package GaleraArbitrator;
use strict;
use warnings;
use DBI;


# The purpose of this module is to oversee the cluster, and determine it's overall state.
# And then react to some specific conditions.
# In particular:
# When the cluster is split due to primary data centre down, we should give Primary to the secondary data centre.

use parent 'Wakeup';
use Class::Tiny qw(
 mode
 nodes
 ),
{ 
    DBI_string   => 'DBI:mysql:host=localhost',
    User         => 'root',
    Password     => '',  #uHuNUvH1fX2T
    cluster_size => 0
 }
;

my $singleton;
my @node_status;
my $scram_segment;


sub BUILD {
    my $self=shift;
    $singleton = $self;
    $self->{mode} = 'NORMAL';

}


# There is not much point tracking status here, since the status can change and we are out of date.
# How about a state engine?
# We are really trying to recognise
# - One server goes to Segment: enter a "scram" mode, then ask for all statuses
# - After 3 seconds in Scram mode, see what we have. And enter a 'alternate' mode.
# In alternate mode, we are waiting to hear from more nodes.
# What then? The primary data centre will not be happy!


sub db_status_report {
    my $self = $singleton;
    my $peer_id = shift;
    my $peer_status = shift;
    my $peer_primary = shift;

    print "We are given a status report by $peer_id and the status is $peer_status\n";
    print "Mode is currently $self->{mode}\n";
    if ( $self->{mode} eq 'SCRAM' ) {
	# Record the status of this node.
	$node_status[$peer_id] = $peer_status;
	print "Setting status to 	$node_status[$peer_id] \n";
    }

    if ( $self->{mode} eq 'NORMAL') {
	if ( $peer_status eq 'segment' && $peer_primary eq 'non-primary' ) {
	    # The peer has determined that it is in "segment" state.
	    # That is, all nodes up in its data centre, and no other nodes up, and non-Primary.
	    $self->start_scram($peer_id);
	}
    }
}

sub start_scram {
    print "Scram!\n";
    my $self = shift;
    my $peer_id = shift;
    # SCRAM (named after movie China Syndrome)
    $self->{mode} = 'SCRAM';
    $self->{scram_peer} = $peer_id;
    my $config = ClusterConfig::nodeByTypeId('Server',$peer_id);
    $scram_segment = $config->{segment};
	
    # Clear knowledge of any statuses
    @node_status = [];

    # Ask for status request from all servers
    #    ArbitratorServer->request_all_status();
    Correspondent::send_all('Server','request_status',1);

    
    # Check back in 3 seconds
    $self->set_wakeup('check_scram',5);
}


sub check_scram {
    print "Checking the scram.\n";
    my $self = shift;
    if ( $self->{mode} ne 'SCRAM' ) {
	return;
    }

    # Check with Config to see what all the nodes should be
    my $trigger = 1;
    for (my $id=0; $id < ClusterConfig::server_count(); $id++) {
	my $config_node = ClusterConfig::nodeByTypeId('Server',$id);
	if ($config_node->{segment} == $scram_segment) {
	    if ( $node_status[$id] ne 'segment' ) {
		$trigger = 0;
		print "Node {$id} has status $node_status[$id] - not segment\n";
	    }
	} else {
	    if (defined $node_status[$id]) {
		$trigger = 0;
		print "Node {$id} gave a response\n";
	    }
	}
    }
    if ($trigger == 1) {
	$self->implement_primary();
    } else {
	$self->cancel_scram();
    }
    
}

sub implement_primary() {
    my $self = shift;
    # We need to tell just one of the nodes to make that segment primary.
    # Which node shall we tell? The first one that told us about the segment status.
    Correspondent::send_one('Server',$self->{scram_peer},'make_primary',1);
}

sub cancel_scram {
    print "Cancel Scram.\n";
    my $self      = shift;
    $self->{mode} = 'NORMAL';
    $self->set_wakeup('check_scram',-1);
}

1;



# Trying to discern this series of events:

# a) We had a cluster of 4: "Code green"
# b) We got cut to a cluster of 2
# c) The 2 are in this secondary data centre
# d) We are now non-primary

# Then, we are code red, and begin this alorithm:
# Send a packet to arbitor, saying "code red"
# (Presumably, our peer will also do that.)
# Wait for response from arbitor saying "go"
# (Or maybe, the arbitor will give that to our peer instead.)
# Then restart cluster

# We move to code black if we get primary again.
# We move to code green if we get back to 4 servers. 
# e) We still have comms with arbitor
# f) Arbitor no longer has comms with Primary data centre.


#Occasionally poll the status.
#    Listen for wsrep notify events.
#
#    Know the status.
#    Know when primary is lost.
#    Know about peers.
#    Be ready to act.


#Need to detect  Change in status.
#    Need a state diagram.
    
