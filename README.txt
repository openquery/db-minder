------------
Module names
------------
The network consists of Clients, Servers, and possibly an Arbitrator.
There is a module for each of these to implement its own logic.
There are modules to handle the communications between nodes - for example, a Client node needs to communicate with several Server nodes, so it will have several instance of the ClientServer module. 

minder.pl - main script will determine whether to act as a Client, Server or Arbitrator.

GaleraArbitrator - controls the promotion of a db node to primary
ArbitratorServer - runs in the arbitrator, to communicate with servers


GaleraServer - communicates with the mysqld process, and manages it.
ServerArbitrator

Client
ClientServer

Wakeup
Config - the actual configuration
ClusterConfig - the module that interprets and encapsulates the configuration
Correspondent - parent class for the various corresponding modules

-------------------------------------------
The language that goes through the messages
-------------------------------------------

Every message has
sender receiver verb parameters

Every message descibes the (new) current state, and does not depend on the previous state.
    For example, we never say "The state has changed." Instead we say "The current state is.."
Some messages need to be acknowledged with a reply or with ack.
    If no acknowledgement is received within 3 seconds, the messages is re-sent.
There is no need to subscribe or connect. Messages will be sent to every node in the config file and no others. 


Generic Verbs:
    ack  - this is an acknowledgement - no further action required.

Server->Arbitrator verbs
    db_status_report  (ack) sent regularly, or in response to request_status

Arbitrator->Server verbs
    make_primary
    request_status  "Please send a status report now!"

Client->Server verbs

Server->Client verbs
    db_status_report  (ack) sent regularly


sender and receiver is the type, and the serial. These are identified in the config file.
Party types are:
dbserver - the pl script look after a mariadb server
wsrep_notify_cmd - the shell script triggered by galera
dbclient - the pl script minding a glb daemon
arbitrator -
command - commands entered by keyboard

wsrep_notify_cmd   and the parameters of that


db_status  {running} {primary} {group}
A status report sent from db node to arbitrator


Now, arbitrator wants to know if a db node is alive. All it can do is send a status request, which should be answered immediately.
status_request
set_primary     An instructon from the arbitrator to set this cluster as primary.
status_summary  a list of the status of all nodes

Human sends message to arbitrator:
status_summary
drain {node}  - drain a node


Nodes must contact arbitrator first.
Arbitrator keeps a note of them, to return the messages.

A site-wide config file will be used, containing all the data we need.
That is, the IP address of the arbitrator, and of each db node.
And maybe more information to come.
Oh yes, which is the primary and secondary data centre.



-------------------------
Configuration.
The configuration of the entire setup is in the database. 
Nodes only need to know how to connect to the database, then they have access to the config.
Nodes will store a local copy of the config, to be used in case they lose contact with the database.

