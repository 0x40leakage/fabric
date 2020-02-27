Kafka uses the same conceptual “leader and follower” configuration used by Raft, in which transactions (which Kafka calls “messages”) are **replicated** from the leader node to the follower nodes. In the event the leader node goes down, one of the followers becomes the leader and ordering can continue, ensuring fault tolerance, just as with Raft.

The management of the Kafka cluster, including the coordination of tasks, cluster membership, access control, and controller election, among others, is handled by a ZooKeeper ensemble and its related APIs.

Each channel maps to **a separate *single-partition* topic** in Kafka.

When an OSN receives transactions via the `Broadcast` RPC, it checks to make sure that the broadcasting client has permissions to write on the channel, then relays (i.e. **produces**) those transactions to the appropriate partition in Kafka. This partition is also consumed by the **OSN** which groups the received transactions into blocks locally, **persists** them in its local ledger, and serves them to receiving clients via the `Deliver` RPC.