package GaleraServer;
use strict;
use warnings;
use DBI;
# use parent 'Correspondent';

# status_running is unknown, down, up
# status_serving is unknown, off, on
# status_primary is unknown, yes, no
# status_group is complete, single, partial, segment, down
#   complete: all nodes are up in cluster.
#   single: only this node - no peers are connected.
#   partial: some nodes are up - more than one, less than all nodes. 
#   datacentre: special case of partial - all of this DC nodes are in cluster, none of other DC
#   down: this node is down - so it doesn't matter what other nodes are up to. 
use ClusterConfig;
use parent 'Wakeup';
use Class::Tiny qw(
 status_running
 status_serving
 status_primary
 status_group
 access
 dbh

 notify_status
 notify_uuid
 notify_primary
 notify_index
 notify_members

 wsrep_cluster_size
 wsrep_cluster_state_uuid
 wsrep_cluster_status
 wsrep_connected
 wsrep_desync_count
 wsrep_gcomm_uuid
 wsrep_incoming_addresses
 wsrep_last_committed
 wsrep_local_state
 wsrep_local_state_comment
 wsrep_local_state_uuid
 wsrep_ready
 ),
{ 
    DBI_string   => 'DBI:mysql:host=localhost',
    User         => 'root',
    Password     => '',  #uHuNUvH1fX2T
    cluster_size => 0
 }
;

my $singleton;

sub BUILD {
    my $self=shift;
    $singleton = $self;
    $self->{status_running} = 'unknown';
    $self->{status_serving} = 'unknown';
    $self->{status_primary} = 'unknown';
    $self->{status_group}   = 'unknown';
    $self->set_wakeup('poll',1);
    $self->{wsrep_cluster_name} = 'unknown';
    $self->{wsrep_node_name} = 'unknown';
}

sub connect {
    my $self = shift;
    $self->{dbh} = DBI->connect($self->DBI_string, $self->User, $self->Password,{'RaiseError' => 0});
}

#sub config {
#    my $self = shift;
#    $self->{config_ip} = shift;
#    $self->{config_cluster} = shift;
#    $self->{config_cluster_size} = 0;
#    my $ip = "|$self->{config_ip}|";
#    foreach my $i (0 .. @{$self->{config_cluster}} - 1 ) {#
##
#	my $peers = $self->{config_cluster}->[$i];#
#	my $count =  ($peers =~ tr/|//) - 1;
#	$self->{config_cluster_size} += $count;
#	if (index($peers, $ip) != -1) {
#	    $self->{config_datacentre} = $i;
#	    $self->{config_local_cluster_size} = $count;
#	} 
#
#    }
#    # Put some loggging info about what config we are running.
#    
# 
#}

sub wsrep_notify_cmd {
    my @parms = shift;
    my $self = $singleton;
   
    if ( shift @parms ne '--status') {
	print "status not found\n";
	return;
    }
    $self->{'notify_status'} = shift @parms;

    if ( shift @parms ne '--uuid') {
	print "uuid not found\n";
	return;
    }
    $self->{'notify_uuid'} = shift @parms;

        if ( shift @parms ne '--primary') {
	print "primary not found\n";
	return;
    }
    $self->{'notify_primary'} = shift @parms;

        if ( shift @parms ne '--index') {
	print "index not found\n";
	return;
    }
    $self->{'notify_index'} = shift @parms;

    if ( shift @parms ne '--members') {
	print "member not found\n";
	return;
    }
    $self->{'notify_members'} = shift @parms;

    $self->poll();

}

sub poll {
    my $self = shift;

    my $previous_status = $self->get_status();
    
	
    # Connect to the database.
    $self->connect();
    if (! defined $self->{dbh} ) {
	print "database not connected\n";
	$self->{status_running} = 'down';
	$self->{status_serving} = 'down';
	$self->{status_primary} = 'down';
	$self->{status_group}   = 'down';
	return;
    }


    my $sth = $self->{dbh}->prepare("SHOW STATUS WHERE Variable_name in ( 
 'wsrep_cluster_size',
 'wsrep_cluster_state_uuid',
 'wsrep_cluster_status',
 'wsrep_connected',
 'wsrep_desync_count',
 'wsrep_gcomm_uuid',
 'wsrep_incoming_addresses',
 'wsrep_last_committed',
 'wsrep_local_state',
 'wsrep_local_state_comment',
 'wsrep_local_state_uuid',
 'wsrep_ready'
)");
    $sth->execute();
    while (my $ref = $sth->fetchrow_hashref()) {
        $self->{$ref->{'Variable_name'}} = $ref->{'Value'};
    }
    $sth->finish();


    $sth = $self->{dbh}->prepare("SHOW GLOBAL VARIABLES WHERE Variable_name in ( 
 'wsrep_cluster_name',
 'wsrep_node_name'
)");
    $sth->execute();
    while (my $ref = $sth->fetchrow_hashref()) {
        $self->{$ref->{'Variable_name'}} = $ref->{'Value'};
#        print "Found a row: id = $ref->{'Variable_name'}, name = $ref->{'Value'}, recorded = $self->{$ref->{'Variable_name'}} \n";
    }
    $sth->finish();

    
    # Disconnect from the database.
    $self->{dbh}->disconnect();

    $self->{status_running} = 'up';
    
    if ($self->{wsrep_ready} eq 'ON' ) {
	$self->{status_serving} = 'serving';
    } else {
	$self->{status_serving} = 'unavailable';
    }

    if ($self->{wsrep_cluster_status} eq 'Primary' ) {
	$self->{status_primary} = 'primary';
    } else {
	$self->{status_primary} = 'non-primary';
    }
	
    $self->deduce_status_group();
    my $current_status = $self->get_status();
    if ($previous_status ne $current_status) {
	print "New status $current_status\n";
	ServerArbitrator->new_status();
    }
    $self->set_wakeup('poll',6);
}

sub deduce_status_group {
    my $self = shift;
    my $expected_server_count = ClusterConfig::server_count();
    print "Live nodes = $self->{'wsrep_cluster_size'}. Config nodes = $expected_server_count \n";
    if ( $self->{'wsrep_cluster_size'} == $expected_server_count  ) {
	$self->{status_group} = 'complete';
	return;
    } 


    # Check for status "segment" - meaning that all nodes in this data centre up, but no others are.
    if ( $self->{'wsrep_cluster_size'} = ClusterConfig->node()->{nodes_in_segment} ) {
	
	#Are all the nodes of my data centre up?
        my @live_peers = split( /,/ , $self->{wsrep_incoming_addresses});
##	my $local_peers = $self->{config_cluster}->[$self->{config_datacentre}];
	my $peer_count = 0;
	my $alien_count = 0;
	foreach my $i (0 .. @live_peers-1 ) {
	    my $peer = $live_peers[$i];
	    my $loc = index($peer, ":");
	    $peer = substr($peer,0,$loc);
	    print "Considering $peer\n";
	    my $peer_node = ClusterConfig::nodeByGaleraIp($peer);
	    if ( defined $peer_node ) {
		if ($peer_node->{segment} == ClusterConfig::node()->{segment} ) {
		    $peer_count ++;
		    print "Peer_count is now $peer_count\n";
		} else {
		    $alien_count ++;
		    print "Alien_count is now $alien_count \n";
		}
	    } else {
		$alien_count ++;
		print "Undefined, so Alien_count is now $alien_count \n";
	    }
	}
	my $nodes_in_this_segment = ClusterConfig::node()->{nodes_in_segment};
	print "Expecting $nodes_in_this_segment nodes\n";
	if ($peer_count == $nodes_in_this_segment && $alien_count == 0 ) {
	    $self->{status_group} = 'segment';
	    print "Status is segment\n";
	    return;
	} 
    }

    if ( $self->{'wsrep_cluster_size'} == 1 ) {
	$self->{status_group} = 'single';
	return;
    }

    $self->{status_group} = 'partial';
    return;
}

sub get_status {
    my $self = shift;
    return "$self->{wsrep_cluster_name} $self->{wsrep_node_name} $self->{status_running} $self->{status_serving} $self->{status_primary} $self->{status_group}";
}

sub make_primary {
    my $self = shift;

    # We'll do a poll so that we are working with the latest status.
    $self->poll();
    
    # Connect to the database.
    $self->connect();

    if (! defined $self->{dbh} ) {
	print "Cannot make primary - database not connected\n";
	return;
    }

    if ( $self->{status_primary} ne 'non-primary') {
	print "Cannot make primary - status is already primary\n";
	return;
    }

    my $sth = $self->{dbh}->prepare("SET GLOBAL wsrep_provider_options='pc.bootstrap=YES'");
    $sth->execute();
    $sth->finish();
    $self->{dbh}->disconnect();
}    

1;



# Trying to discren this series of events:

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
    
