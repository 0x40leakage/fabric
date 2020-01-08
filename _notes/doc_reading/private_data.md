<!-- https://hyperledger-fabric.readthedocs.io/en/release-1.4/private-data-arch.html -->

- Use case: you want all channel participants to see a transaction while keeping a portion of the data private.
- Use collections when transactions (and ledgers) must be shared among a set of organizations but only a subset of those organizations should have access to some (or all) of the data within a transaction. Additionally, since private data is disseminated peer-to-peer rather than via blocks, use private data collections when **transaction data must be kept confidential from ordering service nodes**.
- Starting in v1.2, Fabric offers the ability to create *private data collections*, which allow a defined subset of organizations on a channel the ability to endorse, commit, or query private data without having to create a separate channel.
- A collection is the combination of 2 elements:
    1. The actual private data
        - Sent peer-to-peer via gossip protocol to only the organization(s) authorized to see it.
        - This data is stored in a private state database on the peers of authorized organizations (sometimes called a “side” database, or “SideDB”), which can be accessed from chaincode on these authorized peers. 
            - Because these databases are kept separate from the database that holds the channel ledger, private data is sometimes referred to as “SideDB”.
        - The **ordering service is not involved** here and does not see the private data. 
        - Because gossip distributes the private data peer-to-peer across authorized organizations, it is required to set up anchor peers on the channel, and configure `CORE_PEER_GOSSIP_EXTERNALENDPOINT` on each peer, in order to bootstrap cross-organization communication.
    2. A hash of that data
        - Endorsed, ordered, and written to the ledgers of every peer on the channel. 
        - The hash serves as evidence of the transaction and is used for state validation and can be used for audit purposes.
    ![](https://hyperledger-fabric.readthedocs.io/en/release-1.4/_images/PrivateDataConcept-2.png)
- Transaction flow with private data:
    1. The client application submits a proposal request to invoke a chaincode function (reading or writing private data) to endorsing peers which are part of authorized organizations of the collection. The private data, or data used to generate private data in chaincode, is sent in a `transient` field of the proposal.
        - 明文发给私密数据集里定义的组织的背书节点去背书。
    2. The endorsing peers simulate the transaction and store the private data in a *transient data store* (a temporary storage local to the peer). They **distribute** the private data, based on the collection policy, to authorized peers via gossip.
    3. The endorsing peer sends the proposal response back to the client. The proposal response includes the endorsed read/write set, which includes public data, as well as a hash of any private data keys and values. No private data is sent back to the client. 
    4. The client application submits the transaction (which includes the proposal response with the private data hashes) to the ordering service. The transactions with the private data hashes get included in blocks as normal. The block with the private data hashes is distributed to all the peers. 
        - In this way, all peers on the channel can validate transactions with the hashes of the private data in a consistent way, without knowing the actual private data.
    5. At block commit time, authorized peers use the collection policy to **determine if they are authorized** to have access to the private data. If they do, they will first check their local transient data store to determine if they have already received the private data at chaincode endorsement time. If not, they will attempt to **pull** the private data from another authorized peer. Then they will validate the private data against the hashes in the public block and **commit the transaction and the block**. Upon validation/commit, the private data is moved to their copy of the private state database and private writeset storage. The private data is then deleted from the transient data store.
- In some of these cases, the private data only needs to exist on the peer’s private database until it can be replicated into a database external to the peer’s blockchain. The data might also only need to exist on the peers until a chaincode business process is done with it (trade settled, contract fulfilled, etc).
- To support these use cases, private data can be purged if it **has not been modified for a configurable number of blocks**. 
- Purged private data cannot be queried from chaincode, and is not available to other requesting peers.
- The collection definition gets deployed to the channel at the time of chaincode instantiation (or upgrade). 
    - If using the peer CLI to instantiate the chaincode, the collection definition file is passed to the chaincode instantiation using the `--collections-config` flag.
    - https://godoc.org/github.com/hyperledger/fabric-sdk-go/pkg/client/resmgmt#InstantiateCCRequest
- A collection definition contains one or more collections, each having a policy definition listing the organizations in the collection, as well as properties used to control dissemination of private data at endorsement time and, optionally, whether the data will be purged.
	
    ```json
    [
        {
            "name": "collectionMarbles",
            "policy": "OR('Org1MSP.member', 'Org2MSP.member')",
            "requiredPeerCount": 0,
            "maxPeerCount": 3,
            "blockToLive":1000000,
            "memberOnlyRead": true
        },
        {
            "name": "collectionMarblePrivateDetails",
            "policy": "OR('Org1MSP.member')",
            "requiredPeerCount": 0,
            "maxPeerCount": 3,
            "blockToLive":3,
            "memberOnlyRead": true
        }
    ]
    ```

    - `name`: Name of the collection.
    - `policy`: The private data collection distribution policy defines which organizations’ peers are allowed to persist the collection data expressed using the `Signature` policy syntax, with each member being included in an `OR` signature policy list. 
        - To support read/write transactions, the private data distribution policy must define a broader set of organizations than the chaincode endorsement policy, as peers must have the private data in order to endorse proposed transactions. 
            - 私密数据不能发给不在集合里的组织的 peer，否则不再私密。若私密数据集的范围比 cc 背书策略里的小，则发给私密数据集范围外的组织的 peer 也可完成背书，也可以拿到私密数据。所以要控制 cc 背书策略的组织范围小于等于私密数据集里定义的组织。
    - `requiredPeerCount`: Minimum number of peers (across authorized organizations) that each endorsing peer must successfully disseminate private data to before the peer signs the endorsement and returns the proposal response back to the client. Requiring dissemination as a condition of endorsement will ensure that private data is available in the network even if the endorsing peer(s) become unavailable (during block commit time for other authorized peers to pull private data from). 
        - When `requiredPeerCount` is 0, it means that no distribution is required, but there may be some distribution if `maxPeerCount` is greater than zero. 
        - A `requiredPeerCount` of 0 would typically not be recommended, as it could lead to loss of private data in the network if the endorsing peer(s) becomes unavailable. Typically you would want to require at least some distribution of the private data at endorsement time to ensure redundancy of the private data on multiple peers in the network.
    - `maxPeerCount`: For data redundancy purposes, the maximum number of **other peers** (across authorized organizations) that each endorsing peer will attempt to distribute the private data to. 
        - If an endorsing peer becomes unavailable between endorsement time and commit time, other peers that are collection members but who did not yet receive the private data at endorsement time, will be able to pull the private data from peers the private data was disseminated to. 
        - If this value is set to 0, the private data is not disseminated at endorsement time, forcing private data pulls against endorsing peers on all authorized peers at commit time.
        - `blockToLive`: Represents how long the data should live on the private database in terms of blocks. The data will live for this specified number of blocks on the private database and after that it will get purged, making this data obsolete from the network so that it cannot be queried from chaincode, and cannot be made available to requesting peers. 
            - To keep private data indefinitely, that is, to never purge private data, set the `blockToLive` property to 0.
    - `memberOnlyRead`: a value of `true` indicates that peers **automatically enforce** that only clients belonging to one of the collection member organizations are allowed read access to private data. If a client from a non-member org attempts to execute a chaincode function that performs a read of a private data, the chaincode invocation is terminated with an error. 
        - Utilize a value of `false` if you would like to encode more granular access control within individual chaincode functions.
- If the endorsing peer cannot successfully disseminate the private data to at least the `requiredPeerCount`, it will return an error back to the client. The endorsing peer will attempt to disseminate the private data to peers of **different organizations**, in an effort to ensure that each authorized organization has a copy of the private data. 
    - Since transactions are not committed at chaincode execution time, the endorsing peer and recipient peers store a copy of the private data in a local transient store alongside their blockchain until the transaction is committed.
- When authorized peers do not have a copy of the private data in their transient data store at commit time (either because they were not an endorsing peer or because they did not receive the private data via dissemination at endorsement time), they will attempt to pull the private data from another authorized peer, for a configurable amount of time based on the peer property `peer.gossip.pvtData.pullRetryThreshold` in the peer configuration `core.yaml` file.
- Considerations when using `pullRetryThreshold`:
    - If the requesting peer is able to retrieve the private data within the `pullRetryThreshold`, it will commit the transaction to its ledger (including the private data hash), and store the private data in its state database, **logically separated** from other channel state data.
    - If the requesting peer is not able to retrieve the private data within the `pullRetryThreshold`, it will commit the transaction to it’s blockchain (including the private data hash), without the private data.
    - If the peer was entitled to the private data but it is missing, then that peer will not be able to endorse future transactions that reference the missing private data - a chaincode query for a key that is missing will be detected (based on the presence of the key’s hash in the state database), and the chaincode will receive an error.
- A single chaincode can reference multiple collections.
    - https://godoc.org/github.com/hyperledger/fabric-chaincode-go/shim#ChaincodeStub.PutPrivateData
- Since the chaincode proposal gets stored on the blockchain, it is also important not to include private data in the main part of the chaincode proposal. A special field in the chaincode proposal called the `transient` field can be used to pass private data from the client (or data that chaincode will use to generate private data), to chaincode invocation on the peer. The chaincode can retrieve the `transient` field by calling the `GetTransient()` API. This `transient` field gets excluded from the channel transaction.
    - https://godoc.org/github.com/hyperledger/fabric-sdk-go/pkg/client/channel#Request
    - https://godoc.org/github.com/hyperledger/fabric-chaincode-go/shim#ChaincodeStub.GetTransient
- If the private data is relatively simple and predictable (e.g. transaction dollar amount), channel members who are not authorized to the private data collection could try to guess the content of the private data via brute force hashing of the domain space, in hopes of finding a match with the private data hash on the chain. Private data that is predictable should therefore include **a random “salt”** that is concatenated with the private data key and included in the private data value, so that a matching hash cannot realistically be found via brute force. The random “salt” can be generated at the client side (e.g. by sampling a secure psuedo-random source) and then passed along with the private data in the `transient` field at the time of chaincode invocation.
- Private data collection can be queried just like normal channel data, using shim APIs `GetPrivateDataByRange(collection, startKey, endKey string)`, `GetPrivateDataByPartialCompositeKey(collection, objectType string, keys []string)`. For the CouchDB state database, JSON content queries can be passed using the shim API `GetPrivateDataQueryResult(collection, query string)`.
    - Limitation:
        - Clients that call chaincode that executes range or rich JSON queries should be aware that they may receive a subset of the result set, if the peer they query has missing private data. Clients can query multiple peers and compare the results to determine if a peer may be missing some of the result set.
        - [ ] Chaincode that executes \(range or rich JSON_ queries\) and updates data in a single transaction is not supported, as the **query results cannot be validated** on the peers that don’t have access to the private data, or on peers that are missing the private data that they have access to. [ ] If a chaincode invocation both queries and updates private data, the proposal request will return an error. [ ] If your application can tolerate result set changes between chaincode execution and validation/commit time, then you could call one chaincode function to perform the query, and then call a second chaincode function to make the updates. 
            - [ ] Query 的结果每个其它的 peer 都要验证？
        - Note that calls to `GetPrivateData()` to retrieve individual keys can be made in the same transaction as `PutPrivateData()` calls, since all peers can validate key reads based on the hashed key version.
- Indexes can be applied to the channel’s state database to enable JSON content queries, by packaging indexes in a `META-INF/statedb/couchdb/indexes` directory at chaincode installation time. Similarly, indexes can also be applied to private data collections, by packaging indexes in a 1META-INF/statedb/couchdb/collections/<collection_name>/indexes` directory. 
    - [An example index](https://github.com/hyperledger/fabric-samples/blob/master/chaincode/marbles02_private/go/META-INF/statedb/couchdb/collections/collectionMarbles/indexes/indexOwner.json).
- Prior to commit, peers store private data in a local transient data store. This data automatically gets purged when the transaction commits. But if a transaction was never submitted to the channel and therefore never committed, the private data would remain in each peer’s transient store. This data is purged from the transient store after a configurable number blocks by using the peer’s `peer.gossip.pvtData.transientstoreMaxBlockRetention` property in the peer `core.yaml` file.
    - [ ] never submitted to the channel how
- To update a collection definition or add a new collection, you can upgrade the chaincode to a new version and pass the new collection configuration in the chaincode upgrade transaction, for example using the `--collections-config` flag if using the CLI. 
    - If a collection configuration is specified during the chaincode upgrade, a definition for each of the existing collections must be included.
- When upgrading a chaincode, you can add new private data collections, and update existing private data collections, for example to add new members to an existing collection or change one of the collection definition properties. 
    - Note that you cannot update the collection `name` or the `blockToLive` property, since a consistent `blockToLive` is required regardless of a peer’s block height.
- Collection updates becomes effective when a peer commits the block that contains the chaincode upgrade transaction. 
    - [ ] Note that collections cannot be deleted, as there may be prior private data hashes on the channel’s blockchain that cannot be removed.
- Starting in v1.4, peers of organizations that are added to an existing collection will automatically fetch private data already committed to the collection before they joined the collection.
    - This private data “reconciliation” also applies to peers that were entitled to receive private data but did not yet receive it — because of a network failure, for example — by keeping track of private data that was “missing” at the time of block commit.
    - Private data reconciliation occurs periodically based on the `peer.gossip.pvtData.reconciliationEnabled` and `peer.gossip.pvtData.reconcileSleepInterval` properties in `core.yaml`. The peer will periodically attempt to fetch the private data from other collection member peers that are expected to have it.

<!-- https://hyperledger-fabric.readthedocs.io/en/release-1.4/private_data_tutorial.html -->

# Using private data
## Build a collection definition JSON file

```js
// collections_config.json
[
  {
       "name": "collectionMarbles",
       "policy": "OR('Org1MSP.member', 'Org2MSP.member')",
       "requiredPeerCount": 0,
       "maxPeerCount": 3,
       "blockToLive":1000000,
       "memberOnlyRead": true
  },

  {
       "name": "collectionMarblePrivateDetails",
       "policy": "OR('Org1MSP.member')",
       "requiredPeerCount": 0,
       "maxPeerCount": 3,
       "blockToLive":3,
       "memberOnlyRead": true
  }
]
```

- 交易发到背书策略外的组织：`Event Server Status Code: (10) ENDORSEMENT_POLICY_FAILURE. Description: received invalid transaction. fromOrg: icbc, toOrg: zjfae, name: vip, amount: 10004, innerBillNo: 1000012412411052"`
- 许可外的组织查询私密数据：`GET_STATE failed: transaction ID: 2da76ed6564de23c694f69f33d550ffad59a22ceaf1ebb4205f2b4e5fb0b36ef: private data matching public hash version is not available. Public hash version = {BlockNum: 4, TxNum: 0}, Private data version = <nil>`
- Indexes can also be applied to private data collections, by packaging indexes in the `META-INF/statedb/couchdb/collections/<collection_name>/indexes` directory alongside the chaincode.
    - For deployment of chaincode to production environments, it is recommended to define any indexes alongside chaincode so that the chaincode and supporting indexes are deployed automatically as a unit, once the chaincode has been installed on a peer and instantiated on a channel. 
    - The associated indexes are automatically deployed upon chaincode instantiation on the channel when the `--collections-config` flag is specified pointing to the location of the collection JSON file.
    - https://github.com/hyperledger/fabric-samples/tree/master/chaincode/marbles02_private/go