- [ ] 同一个 cc 装在不同 channel 上，装几次，含义

Whether or not users have installed chaincodes for use by external applications, peers also have special system chaincodes that are always present.

Applications always **connect to peers** when they need to access ledgers and chaincodes. The Fabric Software Development Kit (SDK) makes this easy for programmers — its APIs enable applications to connect to peers, invoke chaincodes to generate transactions, submit transactions to the network that will get ordered and committed to the distributed ledger, and **receive events** when this process is complete.  
The application is **notified asynchronously**.

Through a peer connection, applications can execute chaincodes to query or update a ledger. The result of a ledger query transaction is returned immediately, whereas ledger updates involve a more complex interaction between applications, peers and orderers.

应用发起 SDK 的 invoke，SDK 做的事包括发送 proposal，收集各个 peer 签过名的 proposal response 并发送给 orderer。  
账本更新后，Peer 会触发一个通知事件给发起交易的应用。  

A peer can return the results of a query to an application immediately since all of the information required to satisfy the query is in the peer’s local copy of the ledger. Peers **never consult with other peers** in order to respond to a query from an application.

It’s more appropriate to think of a channel as a logical structure that is formed by a collection of physical peers. Peers provide the control point for access to, and management of, channels.

When a peer connects to a channel, its **digital certificate identifies its owning organization via a channel MSP**.  
P1 and P2 have identities issued by CA1. Channel C determines from a policy in its channel configuration that identities from CA1 should be associated with Org1 using ORG1.MSP.  
Whenever a peer connects using a channel to a blockchain network, a policy in the channel configuration uses the peer’s identity to determine its rights. The mapping of identity to organization is provided by a component called a Membership Service Provider (MSP) — it determines how a peer gets assigned to a specific role in a particular organization and accordingly gains appropriate access to blockchain resources. Moreover, a peer can be owned only by a single organization, and is therefore associated with a single MSP. 

Peers as well as everything that interacts with a blockchain network acquire their organizational identity from their digital certificate and an MSP. Peers, applications, end users, administrators and orderers must have an identity and an associated MSP if they want to interact with a blockchain network.  
We give a name to every entity that interacts with a blockchain network using an identity — a *principal*.  

Phase 1: Proposal  
At the end of phase 1, the application is free to discard inconsistent transaction responses if it wishes to do so, effectively terminating the transaction workflow early. If an application tries to use an inconsistent set of transaction responses to update the ledger, it will be rejected.  

Phase 2: Ordering and packaging transactions into blocks

Phase 3: Validation and commit  
At each peer, every transaction within a block is validated to ensure that it has been **consistently endorsed** by all relevant organizations before it is applied to the ledger. **Failed transactions are retained for audit**, but are not applied to the ledger.

Not every peer needs to be connected to an orderer — peers can cascade blocks to other peers using the gossip protocol.

Upon receipt of a block, a peer will **process each transaction in the sequence in which it appears in the block**.  
For every transaction, each peer will **verify** that the transaction has been **endorsed** by the required organizations according to the endorsement policy of the chaincode which generated the transaction. This process of validation verifies that all relevant organizations have generated the same outcome or result. In case the application violates the endorsement policy by sending wrong transactions, the peer is still able to reject the transaction in the validation process of phase 3.

Peer blocks are almost exactly the same as the blocks received from the orderer, except for a valid or invalid indicator on each transaction in the block.

Phase 3 does not require the running of chaincodes — this is done only during phase 1. It means that chaincodes only have to be available on endorsing nodes, rather than throughout the blockchain network. This is often helpful as it **keeps the logic of the chaincode confidential to endorsing organizations**. This is in contrast to the output of the chaincodes (the transaction proposal responses) which are shared with every peer in the channel, whether or not they endorsed the transaction. 

Every time a block is committed to a peer’s ledger, that peer generates an appropriate event. *Block events* include the full block content, while *block transaction events* include summary information only, such as whether each transaction in the block has been validated or invalidated. *Chaincode events* that the chaincode execution has produced can also be published at this time. Applications can register for these event types so that they can be notified when they occur.

This entire transaction workflow process is called *consensus* because all peers have reached agreement on the **order** and **content** of transactions, in a process that is mediated by orderers. Consensus is a multi-step process and applications are only notified of ledger updates when the process is complete — which may happen at slightly different times on different peers.