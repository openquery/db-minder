
#-------------------------
# Put your database servers configuratons in here

# push @servers, {
#    hostname=>        'romeo',          # used to identify the config. What is returned by hostname on the machine.
#    wsrep_node_name=> 'romeo',          # will be checked
#    minder_ip=>       '103.16.130.153', # ip address to communicate between minders
#    minder_port=>     4569,             # UDP port to communicate between minders
#    mysql_ip =>                         # ip address or 'localhost' for server minder to connect
#    mysql_port =>                       # port for server minder to connect
#    client_ip =>                        # ip address for clients to connect
#    client_port =>                      # tcp port for clients to connect
#    segment=>          2,               # segment number AKA  data centre number, or availability zone number.
# };

push @servers, {
    hostname=>        'romeo',
    wsrep_node_name=> 'romeo',
    minder_ip=>       '103.16.130.153',
    minder_port=>     4569,
    mysql_ip => 
    mysql_port =>
    segment=>          2,
};

push @servers, {
    hostname=>   'siera',
    minder_ip=>  '103.230.156.36',
    minder_port=> 3309,
    segment=> 3,
};

push @clients, {
    hostname=>   'tango',
};

#-------------------------
# Put your arbitrators here. Well, I think you only want one arbitrator. 

# push @arbitrators, {
#    hostname=>        'romeo',          # used to identify the config. What is returned by hostname on the machine.
#    minder_ip=>       '103.16.130.153', # ip address to communicate between minders
#    minder_port=>     4569,             # UDP port to communicate between minders
# };

push @arbitrators, {
    hostname=>    'romeo',
    minder_ip=>   '103.16.130.153',
    minder_port=> 4570,
};


1;
