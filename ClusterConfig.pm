package ClusterConfig;
use Sys::Hostname;


# This one configuration file is fit for all the nodes in the cluster: clients, servers, arbitrator.
# The cluster is divided into partitions (data centres)
# There can be some server nodes and some client nodes in each partition. 



my @servers;
my @clients;
my @arbitrators;

require Config;

open (CONFIG, "Config.pm");

while ($record = <CONFIG>) {
    $config .= $record;
}

close(CONFIG);

eval ($config);

my @segments;
my %nodesByGaleraIp;
my $this_hostname;
my $this_node;
my $this_type = shift;
print "This type is $this_type\n";
               # In case we have 2 minders on one host, this distinguishes which one we are now.
               # '' means, not running 2. Otherwise = Server, Client, or Arbitrator

$this_hostname = `hostname`;
$this_hostname =~ s/^\s+|\s+$//g ;
print "My hostname is $this_hostname\n";

my $counter = 0;
my $problem = 0;
my $node;
foreach my $id (0 .. $#servers ) {
    $node = $servers[$id];
    $node->{id}   = $id;
    $node->{type} = 'Server';

    if ( ! defined $node->{hostname} ) {
	print "Server $id has no hostname!\n";
	$problem = 1;
    } else {
	if ( $node->{hostname} eq $this_hostname ) {
	    if ( $this_type eq '' || $this_type eq 'Server') {
		$this_node = $node;
	    }
	}
    }

    if ( ! defined $node->{minder_ip} ) {
	print "Server $id has no minder_ip address\n";
	$problem = 1;
    } else {
	if ( ! defined $node->{galera_ip} ) { $node->{galera_ip} = $node->{minder_ip};    }
	$nodesByGaleraIp->{$node->{galera_ip}} = $node;
	print "Added $node->{galera_ip} \n";
    }

    if ( ! defined $node->{minder_port} ) { $node->{minder_port} = 3309;    }
    if ( ! defined $node->{segment} )     { $node->{segment} = 0;           }

    $segments[ $node->{segment} ] ++;

}

foreach my $id (0 .. $#servers) {
    $node = $servers[$id];
    $node->{nodes_in_segment} = $segments[ $node->{segment} ];
}


foreach my $id (0 .. $#arbitrators ) {
    $node = $arbitrators[$id];
    $node->{id}   = $id;
    $node->{type} = 'Arbitrator';
    if ( ! defined $node->{hostname} ) {
	print "Arbitrator $id has no hostname!\n";
	$problem = 1;
    } else {
	if ( $node->{hostname} eq $this_hostname ) {
	    if ( $this_type eq '' || $this_type eq 'Arbitrator') {
		$this_node = $node;
	    }
	}
    }

    if ( ! defined $node->{minder_ip} ) {
	print "Arbitrator $id has no minder_ip address\n";
	$problem = 1;
    } 

    if ( ! defined $node->{minder_port} ) { $node->{minder_port} = 3309;    }

}



if ( ! defined $this_node ) {
    print "Could not find my self in the config file.\n";
    $problem = 1;
}


if ($problem == 1) {
    print "Cannot continue due to configuratio problems.\n";
    die;
}


sub node             { return $this_node;     }

sub server_count     { return $#servers + 1;  }

sub nodeByGaleraIp   {
#    my $klass = shift;
    my $IP = shift;
    print "Loking for $IP\n";
    return $nodesByGaleraIp->{$IP} ;
}

sub nodeByTypeId     {
    my $type = shift;
    my $id   = shift;
    my $ip   = shift;
    my $port = shift;
    if ( $type eq 'Server' )     {	$node = $servers[$id];    }
    if ( $type eq 'Arbitrator' ) {	$node = $arbitrators[$id];    }
    if ( $type eq 'Client' )     {	$node = $clients[$id];    }

    return $node;
}

    
1;

