http://thesecretlivesofdata.com/raft/  
https://raft.github.io/raft.pdf  

The **go-to ordering service choice** for production networks, the Fabric implementation of the established Raft protocol uses a “*leader and follower*” model, in which a leader is dynamically elected among the ordering nodes in a channel (this collection of nodes is known as the “*consenter set*”), and that leader replicates messages to the follower nodes.   
Because the system can sustain the loss of nodes, including leader nodes, as long as there is a **majority** of ordering nodes (what’s known as a “*quorum*”) remaining, Raft is said to be “crash fault tolerant” (CFT). In other words, if there are three nodes in a channel, it can withstand the loss of one node (leaving two remaining). If you have five nodes in a channel, you can lose two nodes (leaving three remaining nodes).

*Log entry*  
The primary unit of work in a Raft ordering service is a “log entry”, with the **full sequence of such entries** known as the “*log*”. We consider the log consistent if a majority (a quorum, in other words) of members agree on the entries and their order, making the logs on the various orderers replicated.

*Consenter set*  
The ordering nodes actively participating in the consensus mechanism for a given channel and receiving replicated logs for the channel. This can be all of the nodes available (either in a single cluster or in multiple clusters contributing to the system channel), or a subset of those nodes.

*Finite-State Machine* (FSM)   
Every ordering node in Raft has an FSM and collectively they’re used to ensure that the sequence of logs in the various ordering nodes is deterministic (written in the same sequence).  

*Quorum*  
Describes the minimum number of **consenters** that need to affirm a proposal so that transactions can be ordered. For every consenter set, this is a **majority** of nodes. In a cluster with five nodes, three must be available for there to be a quorum. If a quorum of nodes is unavailable for any reason, the ordering service cluster becomes unavailable for both read and write operations on the channel, and no new logs can be committed.

*Leader*   
At any given time, a channel’s consenter set elects a single node to be the leader. The leader is responsible for ingesting new log entries, replicating them to follower ordering nodes, and managing when an entry is considered committed. This is not a special type of orderer. It is only a **role** that an orderer may have at certain times, and then not others, as circumstances determine.

*Follower*  
Followers receive the logs from the leader and replicate them deterministically, ensuring that logs remain consistent. Followers also receive “heartbeat” messages from the leader. In the event that the leader stops sending those message for a configurable amount of time, the followers will initiate a leader election and one of them will be elected the new leader.

**Every channel runs on a separate instance of the Raft protocol**, which allows each instance to elect a different leader. This configuration also allows further decentralization of the service in use cases where clusters are made up of ordering nodes controlled by different organizations. 

While **all Raft nodes must be part of the system channel**, they do not necessarily have to be part of all application channels. Channel creators (and channel admins) have the ability to pick a subset of the available orderers and to add or remove ordering nodes as needed (as long as only a single node is added or removed at a time).  
While this configuration creates more overhead in the form of redundant heartbeat messages and goroutines, it lays necessary groundwork for BFT.

In Raft, transactions (in the form of proposals or configuration updates) are automatically **routed** by the ordering node that receives the transaction to the current leader of that channel. This means that peers and applications do not need to know who the leader node is at any particular time. Only the ordering nodes need to know.  
When the orderer validation checks have been completed, the transactions are ordered, packaged into blocks, consented on, and distributed.

Raft nodes are always in one of three states: follower, candidate, or leader. All nodes initially start out as a follower. In this state, they can accept log entries from a leader (if one has been elected), or cast votes for leader. If no log entries or heartbeats are received for a set amount of time (for example, five seconds), nodes **self-promote** to the candidate state. In the candidate state, nodes request votes from other nodes. If a candidate receives a quorum of votes, then it is promoted to a leader. The leader must accept new log entries and replicate them to the followers.

While it’s possible to keep all logs indefinitely, in order to save disk space, Raft uses a process called “snapshotting”, in which users can **define how many bytes of data will be kept in the log**. This amount of data will conform to a certain number of blocks (which depends on the amount of data in the blocks. Only **full blocks** are stored in a snapshot).  
For example, let’s say lagging replica R1 was just reconnected to the network. Its latest block is 100. Leader L is at block 196, and is configured to snapshot at amount of data that in this case represents 20 blocks. R1 would therefore receive block 180 from L and then make a `Deliver` request for blocks 101 to 180. Blocks 180 to 196 would then be replicated to R1 through the normal Raft protocol.