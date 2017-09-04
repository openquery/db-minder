package GaleraClient;

# This class models a single instance of the glbd. 
# It communicates with the glbd, and with the database nodes, and with other minders.
# It decides the weightings to be used in the glbd, and advises glbd of those weightings.

use strict;
use warnings;
use DBI;

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
    $self->set_wakeup('poll',1);
    ClusterConfig::create_Servers();
}

sub single() {
    return $singleton;
}

sub poll {
    my $self = shift;
    print "Client is polling!";
    getinfo();
    $self->set_wakeup('poll',6);

    # The regular polling to be done is
    # Check each db node for its up status
    # Check for new configuration information
    # Check that minder is still running correctly. 

}

sub glb_connect {
    # Open a tcp socket to the minder
    my $message = shift;
    my $socket = new IO::Socket::INET (
	PeerAddr => ClusterConfig::node()->{glb_ip},
	PeerPort => ClusterConfig::node()->{glb_port},
	Proto    => 'tcp',
	) or die "ERROR in Socket Creation for glb : $! \n";
    $socket->send($message,0);
    my $peer_data;
    $socket->recv($peer_data,1024);
    return $peer_data;
}

sub getinfo {
    # Send "getinfo"
    my $result = glb_connect("getinfo\n");
    print $result;
    ### Interpret result
}

sub setweights {
    # This sets or adjusts weights, or adds or removes db nodes
    my $message = 'hello';
    my $result = glb_connect($message);
    print $result;
    ### Check result = Ok
}



1;

