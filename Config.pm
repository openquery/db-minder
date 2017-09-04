
#-------------------------
# Put your database servers configuratons in here

# push @servers, {
#    instance_name=>   'serv1',          # Used to identify instances of minder, eg if hostname is not unique.
#    hostname=>        'romeo',          # Used to identify instances of minder if instance_name is not set. What is returned by hostname on the machine.
#    minder_ip=>       '103.16.130.153', # my ip address for communication between minders
#    minder_port=>     4569,             # (4569) my UDP port to communicate between minders
#    segment=>          2,               # segment number AKA  data centre number, or availability zone number.

#    mysql_ip =>                         # (localhost) ip address or 'localhost' for server minder to connect to mysqld
#    mysql_port =>                       # (3306) port for server minder to connect
#    client_ip =>                        # (same as mysql_ip) ip address for clients to connect to mysqld
#    client_port =>                      # (same as mysql_port) tcp port for clients to connect to mysqld
#    wsrep_node_name=> 'romeo',          # will be checked
# };

push @servers, {
    instance_name=>   'server1',
    hostname=>        'romeo',
    minder_ip=>       '127.0.0.1',
    minder_port=>     4569,
    segment=>          2,

    wsrep_node_name=> 'romeo',
    mysql_ip => 
    mysql_port =>
};

push @servers, {
    instance_name=> 'server2',
    hostname=>   'siera',
    minder_ip=>  '127.0.0.1',
    minder_port=> 3309,
    segment=> 3,
};

#----------------------------
# Put your clients here.
# It is possible to have more than one glb daemon on a node to partition the load into various categories. Perhaps various applications.
# So it is possible to have several minders on the node.

push @clients, {
    instance_name=> 'client1',
    hostname=>   'tango',
    minder_ip=>  '127.0.0.1',
    minder_port=> 3310,
    segment=> 3,

    glb_ip=> '127.0.0.1',
    glb_port=> 3307,
};

#-------------------------
# Put your arbitrators here. Well, I think you only want one arbitrator. 

# push @arbitrators, {
#    hostname=>        'romeo',          # used to identify the config. What is returned by hostname on the machine.
#    minder_ip=>       '103.16.130.153', # ip address to communicate between minders
#    minder_port=>     4569,             # UDP port to communicate between minders
# };

push @arbitrators, {
    instance_name=> 'arb1',
    hostname=>    'romeo',
    minder_ip=>   '127.0.0.1',
    minder_port=> 4570,
};

#-------------------------
# Put your command line client here.

# push @commands, {
#    hostname=>        'romeo',          # used to identify the config. What is returned by hostname on the machine.
#    minder_ip=>       '103.16.130.153', # ip address to communicate between minders
#    minder_port=>     4569,             # UDP port to communicate between minders
# };

push @commands, {
    instance_name=> 'cli',
    minder_ip=>   '127.0.0.1',
    minder_port=> 4571,
};


1;
