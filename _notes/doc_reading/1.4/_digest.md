- [ ] channel configuration: channel.tx or genesis.block (network configuration?) or what?
    - [ ] 如何查看 channel.tx 和 genesis.block 的内容
- [ ] channel 实体是什么，如何做到隔离
- [ ] 初始化合约是否通过发交易
- [ ] 签名验签具体过程
    - [ ] digitally signed transaction response 是 cc 负责签名的还是 peer 负责签名
- [x] orderer 属于各家组织是否正当
    - https://hyperledger-fabric.readthedocs.io/en/release-1.4/_images/membership.diagram.2.png

An ordering service uses the *system channel*.  
There is also a special system channel defined for use by the ordering service. It behaves in exactly the same way as a regular channel.

*System chaincodes* ensure that endorsement policies are enforced and upheld. Prior to commitment, the peers will employ these system chaincodes to make sure that enough endorsements are present, and that they were derived from the appropriate entities.

The network is formed when an orderer is started. It’s helpful to think of the ordering service as the initial administration point for the network.

Certificates can be used to sign transactions to indicate that an organization endorses the transaction result.  
The **mapping** of certificates to member organizations is achieved by via a **structure** called a Membership Services Provider (MSP). Network configuration NC4 uses a named MSP to identify the properties of certificates dispensed by CA4 which associate certificate holders with organization R4. NC4 can then use this MSP name in policies to grant actors from R4 particular rights over network resources. An example of such a policy is to identify the administrators in R4 who can add new member organizations to the network.  
X.509 certificates are used in client application transaction proposals（表示交易来自哪家组织） and smart contract transaction responses to digitally sign transactions. Subsequently the network nodes who host copies of the ledger verify that transaction signatures are valid before accepting transactions onto the ledger.

A *consortium* defines the set of organizations in the network who share a need to **transact** with one another.  
A network administrator defines a consortium X1 that contains two members, the organizations R1 and R2.
A channel is a primary **communications mechanism** by which the members of a consortium can communicate with each other.  
A channel C1 has been created for R1 and R2 using the consortium definition X1. The channel is governed by a channel configuration CC1, completely separate to the network configuration. R3 and R4 have no permissions in this channel. R3 and R4 can only interact with C1 if they are added by R1 or R2 to the appropriate policy in the channel configuration CC1. Specifically, note that R4 cannot add itself to the channel C1 – it must, and can only, be authorized by R1 or R2.  
Once a channel has been created, it is only organizations that are explicitly specified in a channel configuration that have any control over it. Any updates to network configuration NC4 from this time onwards will have no direct effect on channel configuration CC1; for example if consortia definition X1 is changed, it will not affect the members of channel C1.  
Channels provide privacy from other channels, and from the network. Channels provide an efficient sharing of infrastructure while maintaining data and communications privacy.

A key part of a P1’s configuration is an X.509 identity issued by CA1 which associates P1 with organization R1. Once P1 is started, it can join channel C1 using the orderer O4. When O4 receives this join request, it uses the channel configuration CC1 to determine P1’s permissions on this channel. For example, CC1 determines whether P1 can read and/or write information to the ledger L1.  

Client application A1 can use channel C1 to connect to specific network resources – in this case A1 can connect to both peer node P1 and orderer node O4.  
A client application will have an identity that associates it with an organization.  

After a smart contract S5 has been developed, an administrator in organization R1 must install it onto peer node P1. After it has occurred, P1 has full knowledge of S5. Specifically, P1 can see the **implementation logic**（[ ] 源码文件拷过去的？）of S5 – the program code that it uses to access the ledger L1. We contrast this to the S5 interface which merely describes the inputs and outputs of S5, without regard to its implementation.  
Just because P1 has installed S5, the other components connected to channel C1 are unaware of it; it must first be instantiated on channel C1. After instantiation, every component on channel C1 is **aware** of the existence of S5; and in our example it means that S5 can now be invoked by client application A1.  
Although every component on the channel can now access S5, they are not able to see its program logic. This remains private to those nodes who have installed it; in our example that means P1. Conceptually this means that it’s the smart contract **interface** that is instantiated, in contrast to the smart contract **implementation** that is installed. Installing a smart contract shows how we think of it being **physically hosted on a peer**, whereas instantiating a smart contract shows how we consider it **logically hosted by the channel**.  

The most important piece of additional information supplied at instantiation is an *endorsement policy*. It describes which organizations must approve transactions before they will be accepted by other organizations onto their copy of the ledger. The act of **instantiation places the endorsement policy in channel configuration** CC1; it enables it to be accessed by any member of the channel.

A smart contract is installed on a peer node and instantiated on a channel.  

Client applications invoke a smart contract by sending transaction proposals to peers owned by the organizations specified by the smart contract endorsement policy. The transaction proposal serves as input to the smart contract, which uses it to generate an endorsed transaction response, which is returned by the peer node to the client application (SDK).  
It’s these transactions responses that are packaged together with the transaction proposal to form a fully endorsed transaction, which can be distributed to the entire network.  

A peer can only run a smart contract if it is installed on it, but it can know about the interface of a smart contract by being connected to a channel.  
All peer nodes can validate and subsequently accept or reject transactions onto their copy of the ledger. However, only peer nodes with a smart contract installed can take part in the process of transaction endorsement.

A *leader peer* is a node which takes responsibility for distributing transactions from the orderer to the other committing peers in the organization the leader peer belongs to.  
If a peer needs to communicate with a peer in another organization, then it can use one of the anchor peers defined in the channel configuration for that organization.  
Only the anchor peer is optional – for all practical purposes there will always be a leader peer and at least one endorsing peer and at least one committing peer.  

Copies of smart contract will usually be identically implemented using the same programming language, but if not, they must be semantically equivalent.

As the network and channels evolve, so will the network and channel configurations. There is a process by which this is accomplished in a controlled manner – involving configuration transactions which capture the change to these configurations. Every configuration change results in a new configuration block transaction being generated.  
Network and channel are important because they encapsulate the **policies** agreed by the network members, which provide a **shared reference** for controlling access to network resources. Network and channel configurations also contain **facts** about the network and channel composition, such as the name of consortia and its organizations.  
Each node in the ordering service records each channel in the network configuration, so that there is a record of each channel created, at the network level.  

Although ordering service node O4 is the actor that created consortia X1 and X2 and channels C1 and C2, the **intelligence** of the network is contained in the network configuration NC4 that O4 is obeying. As long as O4 behaves as a good actor, and correctly implements the policies defined in NC4 whenever it is dealing with network resources, our network will behave as all organizations have agreed. In many ways NC4 can be considered more important than O4 because, ultimately, it controls network access.（orderer 遵照网络配置行事）  

The same principles apply for channel configurations with respect to peers. P1 and P2 are likewise good actors. When peer nodes P1 and P2 are interacting with client applications A1 or A2 they are each using the policies defined within channel configuration CC1 to control access to the channel C1 resources.（peer 遵照通道配置行事）  
If A1 wants to access the smart contract chaincode S5 on peer nodes P1 or P2, each peer node uses its **copy** of CC1 to determine the operations that A1 can perform. For example, A1 may be permitted to read or write data from the ledger L1 according to policies defined in CC1.  
While the peers and applications are critical actors in the network, their behaviour in a channel is dictated more by the channel configuration policy than any other factor.  

Network and channel configurations are logically singular – there is one for the network, and one for each channel.  
Even though there is logically a single configuration, it is actually replicated and kept consistent by every node that forms the network or channel.  
In our network peer nodes P1 and P2 both have a copy of channel configuration CC1, and by the time the network is fully complete, peer nodes P2 and P3 will both have a copy of channel configuration CC2. Similarly ordering service node O4 has a copy of the network configuration, but in a multi-node configuration, every ordering service node will have its own copy of the network configuration.  

To change a network or channel configuration, an administrator must submit a configuration transaction to change the network or channel configuration. It must be signed by the organizations identified in the appropriate policy as being responsible for configuration change. This policy is called the *mod_policy*.  

The ordering service nodes operate a ***mini-blockchain, connected via the system channel***. Using the system channel ordering service nodes distribute network configuration transactions. These transactions are used to co-operatively maintain a consistent copy of the network configuration at each ordering service node.   
In a similar way, peer nodes in an **application channel** can distribute channel configuration transactions. Likewise, these transactions are used to maintain a consistent copy of the channel configuration at each peer node.（通道配置的交易在对应的应用链上，[ ] 和链上的普通交易如何区分？）  

As well as being the **management point for the network**, the ordering service  is also the **distribution point for transactions**. The ordering service is the component which **gathers** endorsed transactions from applications and **orders** them into transaction blocks, which are subsequently **distributed** to every peer node in the channel. At each of these committing peers, transactions are recorded, whether valid or invalid, and their local copy of the ledger updated appropriately.  
When acting at the channel level, O4’s role is to gather transactions and distribute blocks inside channel C1. It does this according to the policies defined in channel configuration CC1. In contrast, when acting at the network level, O4’s role is to provide a management point for network resources according to the policies defined in network configuration NC4. These roles are defined by different policies within the channel and network configurations respectively.  
*Declarative policy based configuration*  
Policies both define, and are used to control, the agreed behaviours by each and every member of a consortium.  

Policy change is managed by a policy within the policy itself. The *modification policy*, or *mod_policy* for short, is a first class policy within a network or channel configuration that manages change.  
When the network was initially set up, only organization R4 was allowed to manage the network. In practice, this was achieved by making R4 the only organization defined in the network configuration NC4 with permissions to network resources. Moreover, the mod_policy for NC4 only mentioned organization R4 – only R4 was allowed to change this configuration.  

We then evolved the network N to also allow organization R1 to administer the network. R4 did this by **adding R1 to the policies for channel creation and consortium creation**. Because of this change, R1 was able to define the consortia X1 and X2, and create the channels C1 and C2. R1 had equal administrative rights (just) **over the channel and consortium policies** in the network configuration.  
R4 however, could grant even more power over the network configuration to R1. R4 could add R1 to the mod_policy such that R1 would be able to manage change of the network policy too.  
This second power is much more powerful than the first, because R1 now has full control over the network configuration NC4. This means that R1 can, in principle remove R4’s management rights from the network. In practice, R4 would configure the mod_policy such that R4 would need to also **approve** the change, or that all organizations in the mod_policy would have to approve the change.  

The mod_policy defines a set of organizations that are allowed to change the mod_policy itself.