

The language that goes through the messages


Every message has
sender receiver verb parameters

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
