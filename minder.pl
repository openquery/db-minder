#!/usr/bin/perl


#
#Main loop
#  listen for udp from clients
#  listen for udp from peers
#  listen for message from wsrep_notify
#  listen for message from command line
#  poll my own db server
#  attend to timed-out situations
#
#
#Is that a select()? with timeout?
#
#
#
#We need a set of clients. This can be an array of hashes.
#And a set of peers. An array of hashes.
#
#
#


# What we know about a server
# A bunch of wsrep variables
# 


use IO::Socket::INET;
use IO::Select;

use Wakeup;
use GaleraServer;
use GaleraArbitrator;
use Correspondent;
use ServerArbitrator;
use ServerNotify;
use ArbitratorServer;

use ClusterConfig;
# flush after every write
$| = 1;

my ($socket,$received_data);
my ($peeraddress,$peerport);


#  we call IO::Socket::INET->new() to create the UDP Socket and bound 
# to specific port number mentioned in LocalPort and there is no need to provide 
# LocalAddr explicitly as in TCPServer.
$socket = new IO::Socket::INET (
LocalPort => ClusterConfig::node()->{minder_port},
Proto => 'udp',
) or die "ERROR in Socket Creation : $! \n";

Correspondent->initialise($socket);

if ( ClusterConfig::node()->{type} eq 'Server' ) {
    print "Starting a server\n";
    my $local_server = GaleraServer->new();
    my $arbitrator = new ServerArbitrator({server => $local_server});
    $arbitrator->register();
    
}

if ( ClusterConfig::node()->{type} eq 'Arbitrator' ) {
    my $local_arbitrator = GaleraArbitrator->new();
}

if ( ClusterConfig::node()->{minder_port} eq 'Client' ) {
    # the module to figure the weightings and communicate with glb
    # a module to talk with each server
}


my $sel = new IO::Select($socket);



my $wait = 1;
while(1)
{
#    $sel->add($socket);
    @ready = $sel->can_read($wait);
    if (! scalar(@ready)) {
    } else {
	my $peer_data;
        $socket->recv($peer_data,1024);
        my $peer_address = $socket->peerhost();
        my $peer_port = $socket->peerport();
        Correspondent->process_udp_message ($peer_address, $peer_port, $peer_data);
   }

    $wait = Wakeup->wakethem();
  

}
$socket->close();


