package ClusterConfig;
use Sys::Hostname;

# This module wraps the configuration data, and makes it available to the other modules. 
# 
# The configuration file contains the config data for all nodes, not just this one. Clients, servers, and arbitrator.
# The cluster is divided into partitions (data centres)
# There can be some server nodes and some client nodes in each partition. 


# Todo: we want to read the config from the database, and store a local persistent backup copy. 


my @servers;
my @clients;
my @arbitrators;
my @commands;

# Read the actual config data.
#require Config;

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
my $this_instance_name = shift;
print "This instance  is $this_instance_name\n";
               # In case we have 2 minders on one host, this distinguishes which one we are now.

$this_hostname = `hostname`;
$this_hostname =~ s/^\s+|\s+$//g ;
print "My hostname is $this_hostname\n";

my $counter = 0;
my $problem = 0;
my $node;


#  Preen the server config information
foreach my $id (0 .. $#servers ) {
    $node = $servers[$id];
    generic_config($node,'Server',$id);
    
    if ( ! defined $node->{galera_ip} ) { $node->{galera_ip} = $node->{minder_ip};    }
    $nodesByGaleraIp->{$node->{galera_ip}} = $node;
    print "Added $node->{galera_ip} \n";


}


foreach my $id (0 .. $#servers) {
    $node = $servers[$id];
    $node->{nodes_in_segment} = $segments[ $node->{segment} ];
}


# Preen the arbitrators config information

foreach my $id (0 .. $#arbitrators ) {
    $node = $arbitrators[$id];
    generic_config($node,'Arbitrator',$id);
}


# Preen the client config information
foreach my $id (0 .. $#clients ) {
    $node = $clients[$id];
    generic_config($node,'Client',$id);
    if ( ! defined $node->{glb_ip} ) { $node->glb_ip = '127.0.0.1' ; }
    if ( ! defined $node->{glb_port} ) { $node->glb_port = '3307' ; }
}

# Preen the command config information
foreach my $id (0 .. $#commands ) {
    $node = $commands[$id];
    generic_config($node,'Command',$id);
}

#--------------------------------

if ($problem == 1) {
    print "Cannot continue due to configuration problems.\n";
    die;
}


sub generic_config {
    my $node = shift;
    my $type = shift;
    my $id = shift;
    print "Genric config for node id=$id type=$type\n";
    $node->{id}   = $id;
    $node->{type} = $type;
    
    if ( ! defined $node->{hostname} && ! defined $node->{instance_name} ) {
	print "$type $id has no hostname nor instance_name!\n";
	$problem = 1;
    } else {
	if ( $node->{instance_name} eq $this_instance_name ) {
	    print "Instance identified by $this_instance_name\n";
	    $this_node = $node;
	} else {
	    print "this instance is $this_instance_name and node is $node->{instance_name}\n";
	    if ( $this_instance_name eq '' && $node->{hostname} eq $this_hostname ) {
		print "Instance identified by host name $this_hostname\n";
		$this_node = $node;
	    }
	}
	
    }
    
    if ( ! defined $node->{minder_ip} ) {
	print "$type $id has no minder_ip address\n";
	$problem = 1;
    }
    if ( ! defined $node->{minder_port} ) { $node->{minder_port} = 3309;    }
    if ( ! defined $node->{segment} )     { $node->{segment} = 0;           }
    $segments[ $node->{segment} ] ++;

}

sub create_Clients {
    foreach my $id (0 .. $#clients ) {
	$node = $clients[$id];
	Correspondent::create($node);
    }
}

sub create_Servers {
    foreach my $id (0 .. $#servers ) {
	$node = $servers[$id];
	Correspondent::create($node);
    }
}

sub create_Arbitrators {
    foreach my $id (0 .. $#arbitrators ) {
	$node = $arbitrators[$id];
	Correspondent::create($node);
    }
}

sub node             { return $this_node;     }

sub server_count     { return $#servers + 1;  }
sub client_count     { return $#clients + 1;  }
sub arbitrator_count { return $#arbitrators + 1;  }

sub nodeByGaleraIp   {
#    my $klass = shift;
    my $IP = shift;
    print "Looking for $IP\n";
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
    if ( $type eq 'Command' ) {
	# The command nodes are not kept in config.
	# So we just make this up on the spot.
	$node = { type=>'Command', id=>$id, minder_ip=>$ip, minder_port=>$port};
    }

    return $node;
}

    
1;

