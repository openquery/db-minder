package Correspondent;
# This package implements the protocols for communicating between the minder components.;
use strict;
use warnings;
#use Sys::Hostname;
use IO::Socket::INET;

use parent 'Wakeup';
use Class::Tiny qw(
    address
    port
    peer_type
    peer_id
    RecentStamp 
    wakeup_time      
    ),
 { 

 }
;

# A hash of all the correspondents, keyed by Type:IPaddress
my %correspondents;
my $socket;
my $my_type;
my $my_id;

sub initialise {
    my $self = shift;
    $socket = shift;
    $my_type = ClusterConfig::node()->{type};
    $my_id =ClusterConfig::node()->{id};
}

sub create {
    my $peer = shift;
    my $correspondent;
    my $address = $peer->{minder_ip};
    my $port = $peer->{minder_port};
    my $peer_type = $peer->{type};
    my $peer_id = $peer->{id};
    my $key = "|$peer_type|$peer_id|";

    if ( exists $correspondents{$key} ) {
        $correspondent = $correspondents{$key};
        print "Found the correspondent for $key \n";
    } else {
        print "New correspondent with key $key\n";
	my $Klass= "$my_type$peer_type";
	$correspondent = $Klass->new({ peer_id => $peer_id});
	$correspondent->{peer} = $peer;
	$correspondent->{type} = $peer_type;
	$correspondents{$key} = $correspondent;
    }
    $correspondent->{RecentStamp} = time();
    return $correspondent;
}


sub find_correspondent {
    my $correspondent;
    my $address = shift;
    my $port = shift;
    my $peer_type = shift;
    my $peer_id = shift;
    my $key = "|$peer_type|$peer_id|";

    if ( exists $correspondents{$key} ) {
        $correspondent = $correspondents{$key};
        print "Found the correspondent for $key \n";
    } else {
        print "New correspondent with key $key\n";
	my $Klass= "$my_type$peer_type";
	$correspondent = $Klass->new({ peer_id => $peer_id});
	$correspondent->{peer} = ClusterConfig::nodeByTypeId($peer_type, $peer_id, $address, $port);
	if ( $correspondent->{peer}->{minder_ip} ne $address ) {
	    print "Wrong ip address for correspondent. Config=$correspondent->{peer}->{minder_ip}, socket=$address.\n";
	}
	if ($correspondent->{peer}->{minder_port} ne $port) {
	    print "Wrong port for correspondent. Config=$correspondent->{peer}->{minder_ip}, socket=$address.\n";
	}
	$correspondent->{type} = $peer_type;
	$correspondents{$key} = $correspondent;
    }
    $correspondent->{RecentStamp} = time();
    return $correspondent;
}

sub register {
    my $self = shift;
    # print "Building with peer_type = $self->{peer_type}\n";
    # print "Building with peer_id = $self->{peer_id}\n";

    my $key = "|$self->{peer}->{type}|$self->{peer}->{id}|";
    $correspondents{$key} = $self;
}
    


sub send {
    my $self = shift;
    my $message = shift;
    my $ack_required = shift;
    $self->{protocol} = "$my_type $my_id $self->{peer}->{type} $self->{peer}->{id} $message";
    print "Sending $self->{protocol}\n";
    my $socket_address = sockaddr_in($self->{peer}->{minder_port}, inet_aton($self->{peer}->{minder_ip}));
    $socket->send($self->{protocol}, 0, $socket_address );
    if (defined $ack_required) {
	$self->set_wakeup('resend',3);
	$self->{resend_count} = 0;
    } else {
	$self->set_wakeup('resend',-1);
    }
}

sub send_all {
    my $type = shift;
    my $message = shift;
    my $ack_required = shift;
    print "Send all, type=$type, message= $message \n";
    while ( (my $key, my $node) = each %correspondents )
    {
	print "Node = $key \n";
	if ($node->{type} eq $type) {
	    $node->send($message,$ack_required);
	}
    }
    
}

sub send_one {
    my $peer_type = shift;
    my $peer_id = shift;
    my $message = shift;
    my $ack_required = shift;
    my $key = "|$peer_type|$peer_id|";

    print "Send one, type=$peer_type, message= $message \n";
    my $node = $correspondents{$key} ;
    
    print "Node = $key \n";
    if ($node->{type} eq $peer_type) {
	$node->send($message,$ack_required);
    }
}

sub byTypeId {
    my $peer_type = shift;
    my $peer_id = shift;
    my $key = "|$peer_type|$peer_id|";
    my $correspondent = $correspondents{$key} ;
    return $correspondent;
}

sub resend {
    my $self= shift;
    $self->{resend_count} ++;
    $self->set_wakeup('resend',3);
    my $socket_address = sockaddr_in($self->{peer}->{minder_port}, inet_aton($self->{peer}->{minder_ip}));
    $socket->send($self->{protocol}, 0, $socket_address );
    if ($self->{resend_count} % 200 == 1) {
	print "Re-Sending $self->{resend_count} $self->{protocol}\n";
    }
}


sub ack {
    my $self = shift;
    $self->set_wakeup('resend',-1);
}

sub process_udp_message {
    my $self = shift;
    my ($address, $port, $data) = @_;
    my @parms = split ' ',   $data;
    # print "\n($address , $port) said: $data \n";

    my $peer_type = shift @parms;
    my $peer_id = shift @parms;
    my $receiver_type = shift @parms;
    my $receiver_id = shift @parms;
    
    my $correspondent = find_correspondent($address, $port, $peer_type, $peer_id);
    #print ref($correspondent), "\n";

    if ( $parms[0] eq 'ack' ) {
	$correspondent->ack();
    } else {
	$correspondent->receive(\@parms);
    }
	


}

1;


# Here is how resend works:
#
# 1. Some messages do not need resend. In fact, this is the default.
# 2. If a message needs resend, it will be flagged as such
# 3. The send method keeps a copy of the message, and sets an alarm to send it later.
# 4. If an ack  message is recevied, then we cancel the alarm.
# 5. If certain superceding messages are sent, then we cancel the alarm.
# If the alarm fires, we enter the resend method
# 6. The messages is resent, and a counter incremented, and the alarm set again.
# 7. If the message has been sent a few times without ack, then we log it. 
