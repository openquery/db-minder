package GaleraCommand;

# This class is to provide command line interaction withe the minder network.

use strict;
use warnings;
use DBI;

use parent 'Node';
use Class::Tiny qw(
 ),
{ 
 }
;

my $report_time;

sub BUILD {
    my $self=shift;
    ClusterConfig::create_Servers();
    ClusterConfig::create_Clients();
    ClusterConfig::create_Arbitrators();
    
    ### decode command line to understand what needs to be done.
    $self->set_wakeup('status_report',1);

}


sub status_report {
    my $self = shift;
    # Obtain status from all nodes.
    print "Starting status report\n";
    Correspondent::send_all('Server','request_status',1);
    Correspondent::send_all('Client','request_status',1);
    Correspondent::send_all('Arbitrator','request_status',1);
    $self->set_wakeup('complete_status_report',5);
    $self->{report_time} = time();

}

 


sub complete_status_report {
    my $self = shift;
    print "complete status report\n";
    for (my $id=0; $id < ClusterConfig::server_count(); $id++) {
	#my $server = ClusterConfig::nodeByTypeId('Server',$id);
	my $server = Correspondent::byTypeId('Server',$id);
	print "Recent Stamp is $server->{RecentStamp}\n";
	print "Report time is $self->{report_time}\n";
	if ( $server->{RecentStamp} < $self->{report_time} ) {
	    print "Server {$id} did not report\n";
	} else {
	    print "Server {$id} has status !\n";
	}
    }
    for (my $id=0; $id < ClusterConfig::client_count(); $id++) {
	#my $client = ClusterConfig::nodeByTypeId('Client',$id);
	my $client = Correspondent::byTypeId('Client',$id);
	if ( $client->{RecentStamp} < $self->{report_time} ) {
	    print "Client {$id} did not report\n";
	} else {
	    print "Client {$id} has status !\n";
	}

    }
    exit(0);

}

1;

