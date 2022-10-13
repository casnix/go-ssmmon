# {{AppName}}
This is the source specific multicast monitoring (SSMMON) utility to track stability and reachability of an IGMPv3 source across a network.  This is intended for use as a probe in more than one location on a network.  Logging and notifications are planned functions of this utility.  SSMMON is written in Golang to provide a standalone executable that can be built for any OS without dependencies beyond OS/kernel APIs.

## Current version in MASTER: {{ReleaseVersion}}
## Latest build in MASTER: {{BuildVersion}}

## Execution prerequisites
None, really.  

## Build prerequisites
* Golang 1.18.1
* Bash environment (for build scripts) -- can be on Linux or WSL, or something like Cygwin.

To build, run the `build.sh` script in the source root.

## Installation
#### Documentation is on the to-do list.

## Debugging
To debug whats going on call the script with the additional parameter -d or --debug

## Protocol description
The SSMMON protocol can be described in three modes: passive, active restricted, and active promiscuous.  In passive mode, an SSMMON node will only listen for other SSMMON nodes on a channel.  In active mode, an SSMMON node will both listen and try to form "adjacencies" with remote SSMMON nodes depending on if it is in restricted or promiscuous mode.
All three modes can be run in open or protected mode.  In open mode all packets are in cleartext.  In protected mode all packets are encrypted with a shared key, preventing unauthorized announcers from communicating with protected nodes.

### Source announcer neighborship and adjacency
#### In active promiscuous mode

The source announcer (referred to as "announcer" now-on) will listen and announce on a user defined multicast group using IGMPv2.  When a neighbor SSMMON node is configured with another unique group, the announcer will join that group and listen for that source.
If it receives hello packets on the remote node's announcement group, the announcer will consider the remote node a neighbor.  
If the hello packet from the remote node describes timers that match the announcer, then the announcer will send its own hello packet on the remote node's multicast group.  
If the remote node is in active promiscuous mode and agrees with the values in the local announcer's hello packet, it will reciprocate by repeating this process on the local announcer's group.
Once both announcers are hearing eachother on their own local groups, they consider once another to be adjacent.  

#### In active restricted mode

The announcer will listen and announce only on whitelisted groups where whitelisted source hosts are heard using only IGMPv3.  
If a whitelisted source is detected the restricted announcer will go through the process of forming a neighborship and adjacency described above.
If a non-whitelisted source is heard on the restricted announcer's group it will form a neighborship on the non-whitelisted announcer, but the restricted announcer will ignore it.  This prevents the restricted announcer from monitoring a non-whitelisted node, and pushes the non-whitelisted node into the passive mode with regards to the restricted announcer.

#### In passive mode configured by user

The SSMMON node will join the source specific multicast channel for a user defined remote host.  The passive node will form a neighborship in the egress direction with the remote node, but will not send any hello packets.  It will only listen.
This is intended for monitoring a remote SSMMON node either without making your presence known (like a customer searching for an ISP's SSMMON signal to make sure it can hear the service provider).  This can also cut down on network traffic, though the protocol is already very lightweight.

#### In passive mode by a non-responsive remote announcer

In the case where the remote announcer either cannot hear the local announcer, or is a restricted node, the local announcer will make a neighborship in the egress direction and continue to send hello packets to the remote announcer.  
In these cases the local announcer cannot tell if the remote is a restricted node or if the remote is unable to receive packets.


### Hello packets
An announcer sends a hello packet to a remote SSMMON node at a user defined interval (the hello timer).  Listeners count the time between receiving these packets from neighbors and if a user defined period is exceeded (the dead interval), a neighbor is marked as dead.
These packets are used to form neighborships and adjacencies.

#### Format
An announcer sends a hello packet to a user defined multicast group at a user defined interval.  This interval is defined in milliseconds and the default hello timer is 500ms (half a second).  The hello packet has an ascii string in this format:

```
<source group IP>:<source host IP>,<hello timer in milliseconds as 16 bits>,<dead timer in milliseconds as 16 bits>
```

For an example, a hello packet on group 235.4.5.2 from host 10.9.8.7 with a hello timer of 500ms and a dead timer of 1000ms would send a hello packet with this string:
```
235.4.5.2:10.9.8.7,0x01f4,0x03e8
```
This packet would tell a listener that it is receiving a hello packet from 10.9.8.7, and that 10.9.8.7 has a hello timer set to 500ms and a dead timer set to 1000ms.  If this is received on a group other than 235.4.5.2, the listener now knows that 10.9.8.7 is announcing on that group.
