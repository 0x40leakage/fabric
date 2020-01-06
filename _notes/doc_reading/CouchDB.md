<!-- https://hyperledger-fabric.readthedocs.io/en/release-1.4/couchdb_as_state_database.html -->

- LevelDB is the default key-value state database embedded in the peer process. CouchDB is an optional alternative external state database. 
- Like the LevelDB key-value store, CouchDB can store any binary data that is modeled in chaincode (CouchDB attachment functionality is used internally for non-JSON binary data). 
- As a JSON document store, CouchDB additionally enables rich query against the chaincode data, when chaincode values (e.g. assets) are modeled as JSON data.
- If you model assets as JSON and use CouchDB, you can also perform complex rich queries against the chaincode data values, using the *CouchDB JSON query language* within chaincode. These types of queries are excellent for understanding what is on the ledger. 
    - Proposal responses for these types of queries are typically useful to the client application, but are not typically submitted as transactions to the ordering service. In fact, there is no guarantee the result set is stable between chaincode execution and commit time for rich queries, and therefore rich queries are not appropriate for use in update transactions, unless your application can guarantee the result set is stable between chaincode execution time and commit time, or can handle potential changes in subsequent transactions. 
        - For example, if you perform a rich query for all assets owned by Alice and transfer them to Bob, a new asset may be assigned to Alice by another transaction between chaincode execution time and commit time, and you would miss this “phantom” item.
- CouchDB runs as a separate database process alongside the peer, therefore there are additional considerations in terms of setup, management, and operations. You may consider starting with the default embedded LevelDB, and move to CouchDB if you require the additional complex rich queries. 
    - It is a good practice to **model chaincode asset data as JSON**, so that you have the option to perform complex rich queries if needed in the future.
        - [ ] how: see marbles02 chaincode
- The key for a CouchDB JSON document can only contain valid UTF-8 strings and cannot begin with an underscore. Whether you are using CouchDB or LevelDB, you should avoid using U+0000 (nil byte) in keys.
- JSON documents in CouchDB cannot use the following values as top level field names. These values are reserved for internal use.
    - Any field beginning with an underscore `_`
    - `~version`
- Most of the chaincode shim APIs can be utilized with either LevelDB or CouchDB state database, e.g. `GetState`, `PutState`, `GetStateByRange`, `GetStateByPartialCompositeKey`. Additionally when you utilize CouchDB as the state database and model assets as JSON in chaincode, you can perform rich queries against the JSON in the state database by using the `GetQueryResult` API and passing a CouchDB query string.
    - http://docs.couchdb.org/en/stable/api/database/find.html
    - https://github.com/hyperledger/fabric-samples/blob/master/chaincode/marbles02/go/marbles_chaincode.go
- Fabric supports paging of query results for rich queries and range based queries. APIs supporting pagination allow the use of page size and bookmarks to be used for both range and rich queries. 
- To support efficient pagination, the Fabric pagination APIs must be used. Specifically, the CouchDB `limit` keyword will not be honored in CouchDB queries since Fabric itself manages the pagination of query results and implicitly sets the `pageSize` limit that is passed to CouchDB.
    - If a `pageSize` is specified using the paginated query APIs (`GetStateByRangeWithPagination()`, `GetStateByPartialCompositeKeyWithPagination()`, and `GetQueryResultWithPagination()`), a set of results (bound by the `pageSize`) will be returned to the chaincode along with a bookmark. The bookmark can be returned from chaincode to invoking clients, which can use the bookmark in a follow on query to receive the next “page” of results.
- The pagination APIs are for use in read-only transactions only, the query results are intended to support client paging requirements. For transactions that need to read and write, use the non-paginated chaincode query APIs. Within chaincode you can iterate through result sets to your desired depth.
- Regardless of whether the pagination APIs are utilized, all chaincode queries are **bound** by `totalQueryLimit` (default 100000) from `core.yaml`. This is the maximum number of results that chaincode will iterate through and return to the client, in order to avoid accidental or malicious long-running queries.
- Regardless of whether chaincode uses paginated queries or not, the peer will query CouchDB **in batches** based on `internalQueryLimit` (default 1000) from `core.yaml`. This behavior ensures reasonably sized result sets are passed between the peer and CouchDB when executing chaincode, and is transparent to chaincode and the calling client.
- Indexes in CouchDB are required in order to make JSON queries efficient and are required for any JSON query with a sort. 
    - Indexes can be **packaged alongside chaincode** in a `/META-INF/statedb/couchdb/indexes` directory. 
    - Each index must be defined in its own text file with extension `.json` with the index definition formatted in JSON following the [CouchDB index JSON syntax](http://docs.couchdb.org/en/stable/api/database/find.html#db-index).
        - https://github.com/hyperledger/fabric-samples/blob/master/chaincode/marbles02/go/META-INF/statedb/couchdb/indexes/indexOwner.json
- Any index in the chaincode’s `META-INF/statedb/couchdb/indexes` directory will be packaged up with the chaincode for deployment. When the chaincode is both installed on a peer and instantiated on one of the peer’s channels, the index will automatically be deployed to the peer’s channel and chaincode specific state database (if it has been configured to use CouchDB). 
    - If you install the chaincode first and then instantiate the chaincode on the channel, the index will be deployed at chaincode instantiation time. 
    - If the chaincode is already instantiated on a channel and you later install the chaincode on a peer, the index will be deployed at chaincode installation time.
- Upon deployment, the index will automatically be utilized by chaincode queries. 
    - CouchDB can automatically determine which index to use based on the fields being used in a query. 
    - Alternatively, in the selector query the index can be specified using the `use_index` keyword.
- The same index may exist in subsequent versions of the chaincode that gets installed. To change the index, **use the same index name but alter the index definition**. Upon installation/instantiation, the index definition will get **re-deployed** to the peer’s state database.
- If you have a large volume of data already, and later install the chaincode, the index creation upon installation may take some time. Similarly, if you have a large volume of data already and instantiate a subsequent version of the chaincode, the index creation may take some time. 
    - Avoid calling chaincode functions that query the state database at these times as the chaincode query may time out while the index is getting initialized. 
    - During transaction processing, the indexes will automatically get refreshed as blocks are committed to the ledger.
- CouchDB is enabled as the state database by changing the `stateDatabase` configuration option from `goleveldb` to `CouchDB`. Additionally, the `couchDBAddress` needs to configured to point to the CouchDB to be used by the peer. The `username` and `password` properties should be populated with an admin username and password if CouchDB is configured with a username and password. 
    - Additional options are provided in the `couchDBConfig` section and are documented in place. 
- Changes to the `core.yaml` will be effective immediately after restarting the peer.
	
    ```yaml
    state:
        # stateDatabase - options are "goleveldb", "CouchDB"
        # goleveldb - default state database stored in goleveldb.
        # CouchDB - store state database in CouchDB
        stateDatabase: goleveldb
        # Limit on the number of records to return per query
        totalQueryLimit: 100000
        couchDBConfig:
            # It is recommended to run CouchDB on the same server as the peer, and
            # not map the CouchDB container port to a server port in docker-compose.
            # Otherwise proper security must be provided on the connection between
            # CouchDB client (on the peer) and server.
            couchDBAddress: couchdb:5984
            # This username must have read and write authority on CouchDB
            username:
            # The password is recommended to pass as an environment variable
            # during start up (e.g. LEDGER_COUCHDBCONFIG_PASSWORD).
            # If it is stored here, the file must be access control protected
            # to prevent unintended users from discovering the password.
            password:
            # Number of retries for CouchDB errors
            maxRetries: 3
            # Number of retries for CouchDB errors during peer startup
            maxRetriesOnStartup: 10
            # CouchDB request timeout (unit: duration, e.g. 20s)
            requestTimeout: 35s
            # Limit on the number of records per each CouchDB query
            # Note that chaincode queries are only bound by totalQueryLimit.
            # Internally the chaincode may execute multiple CouchDB queries,
            # each of size internalQueryLimit.
            internalQueryLimit: 1000
            # Limit on the number of records per CouchDB bulk update batch
            maxBatchUpdateSize: 1000
            # Warm indexes after every N blocks.
            # This option warms any indexes that have been
            # deployed to CouchDB after every N blocks.
            # A value of 1 will warm indexes after every block commit,
            # to ensure fast selector queries.
            # Increasing the value may improve write efficiency of peer and CouchDB,
            # but may degrade query response time.
            warmIndexesAfterNBlocks: 1
    ```

- You can also pass in docker environment variables to override `core.yaml` values, for example `CORE_LEDGER_STATE_STATEDATABASE` and `CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS`.
- CouchDB hosted in docker containers supplied with Hyperledger Fabric have the capability of setting the CouchDB username and password with environment variables passed in with the `COUCHDB_USER` and `COUCHDB_PASSWORD` environment variables using Docker Compose scripting.
    - For CouchDB installations outside of the docker images supplied with Fabric, the [local.ini](http://docs.couchdb.org/en/stable/config/intro.html#configuration-files) file of that installation must be edited to set the admin username and password.
    - Docker compose scripts only set the username and password at the **creation** of the container. The `local.ini` file must be edited if the username or password is to be changed after creation of the container.
    - CouchDB peer options are read on each peer startup.
- Avoid using chaincode for queries that will result in a scan of the entire CouchDB database. Full length database scans will result in long response times and will degrade the performance of your network.
- Take some of the following steps to avoid long queries:
    1. When using JSON queries:
        - Be sure to create indexes in the chaincode package.
        - Avoid query operators such as `$or`, `$in` and `$regex`, which lead to full database scans.
    2. For range queries, composite key queries, and JSON queries:
        - Utilize paging support (as of v1.3) instead of one large result set.
    3. If you want to build a dashboard or collect aggregate data as part of your application, you can query an off-chain database that replicates the data from your blockchain network. 
        - This will allow you to query and analyze the blockchain data in a data store optimized for your needs, without degrading the performance of your network or disrupting transactions. To achieve this, applications may use block or chaincode events to write transaction data to an off-chain database or analytics engine. 
        - For each block received, the [ ] block listener application would iterate through the block transactions and build a data store using the key/value writes from each **valid** transaction’s `rwset`. 
        - The [peer channel-based event services](https://hyperledger-fabric.readthedocs.io/en/release-1.4/peer_event_services.html) provide replayable events to ensure the integrity of downstream data stores.
        - https://hyperledger.github.io/fabric-sdk-node/release-1.4/index.html tutorials

<!-- https://hyperledger-fabric.readthedocs.io/en/release-1.4/couchdb_tutorial.html -->
- Rich queries are more flexible and efficient against large indexed data stores, when you want to query the actual data value content rather than the keys. CouchDB is a JSON document datastore rather than a pure key-value store therefore enabling indexing of the contents of the documents in the database.
- In order to leverage the benefits of CouchDB, namely content-based JSON queries, your **data must be modeled in JSON format**. 
- You must decide whether to use LevelDB or CouchDB before setting up your network. Switching a peer from using LevelDB to CouchDB is not supported due to data compatibility issues. 
- **All peers on the network must use the same database type**. If you have a mix of JSON and binary data values, you can still use CouchDB, however the binary values can only be queried based on key, key range, and composite key queries.
- A docker image of CouchDB is available and we recommend that it be run on the same server as the peer. You will need to setup one CouchDB container per peer and update each peer container by changing the configuration found in `core.yaml` to point to the CouchDB container. 
- The `core.yaml` file must be located in the directory specified by the environment variable `FABRIC_CFG_PATH`:
    - For docker deployments, `core.yaml` is pre-configured and located in the peer container `FABRIC_CFG_PATH` folder. However when using docker environments, you typically pass environment variables by editing the `docker-compose-couch.yaml` to override the `core.yaml`.
    - For native binary deployments, `core.yaml` is included with the release artifact distribution.
- To view an example of a `core.yaml` file configured for CouchDB, examine the BYFN `docker-compose-couch.yaml` in the `HyperLedger/fabric-samples/first-network` directory.
    - https://github.com/hyperledger/fabric-samples/blob/master/first-network/docker-compose-couch.yaml
- Indexes allow a database to be queried without having to examine every row with every query, making them run faster and more efficiently. Normally, indexes are built for frequently occurring query criteria allowing the data to be queried more efficiently. 
- To leverage the major benefit of CouchDB – the ability to perform rich queries against JSON data – indexes are not required, but they are strongly recommended for performance. Also, if sorting is required in a query, CouchDB requires an index of the sorted fields.
    - Rich queries that do not have an index will work but may throw a warning in the CouchDB log that the index was not found. However, if a rich query includes a sort specification, then an index on that field is required; otherwise, the query will fail and an error will be thrown.
- Marbles data structure:
	
    ```go
    type marble struct {
         ObjectType string `json:"docType"` // docType is used to distinguish the various types of objects in state database
         Name       string `json:"name"`    // the field tags are needed to keep case from bouncing around
         Color      string `json:"color"`
         Size       int    `json:"size"`
         Owner      string `json:"owner"`
    }
    ```

    - The attribute `docType` is a pattern used in the chaincode to differentiate different data types that may need to be queried separately. When using CouchDB, it recommended to include this `docType` attribute to distinguish each type of document in the chaincode namespace. (Each chaincode is represented as its own CouchDB database, that is, **each chaincode has its own namespace for keys**.)
    - `docType` is used to identify that this document/asset is a marble asset. Potentially there could be other documents/assets in the chaincode database. The documents in the database are searchable against all of these attribute values.
- When defining an index for use in chaincode queries, each one must be defined in its own text file with the extension `.json` and the index definition must be formatted in the CouchDB index JSON format.
- To define an index, three pieces of information are required:
    - `fields`: these are the frequently queried fields
    - `name`: name of the index
    - `type`: always `json` in this context
    - Optionally the design document attribute `ddoc` can be specified on the index definition. A [design document](http://guide.couchdb.org/draft/design.html) is CouchDB construct designed to contain indexes. Indexes can be grouped into design documents for efficiency but CouchDB recommends one index per design document.
- When defining an index it is a good practice to include the `ddoc` attribute and value along with the index name. It is important to include this attribute to ensure that you can update the index later if needed. Also it gives you the ability to explicitly specify which index to use on a query.
	
    ```js
    {
        "index":{
            "fields":["docType","owner"] // Names of the fields to be queried
        },
        "ddoc":"indexOwnerDoc", // (optional) Name of the design document in which the index will be created.
        "name":"indexOwner",
        "type":"json"
    }
    ```

    - If the design document `indexOwnerDoc` does not already exist, it is automatically created when the index is deployed. 
- An index can be constructed with one or more attributes specified in the list of `fields` and any combination of attributes can be specified. 
- An attribute can exist in multiple indexes for the same `docType`. 
	
    ```js
    {
        "index":{
            "fields":["owner"] // Names of the fields to be queried
        },
        "ddoc":"index1Doc", // (optional) Name of the design document in which the index will be created.
        "name":"index1",
        "type":"json"
    }

    {
        "index":{
            "fields":["owner", "color"] // Names of the fields to be queried
        },
        "ddoc":"index2Doc", // (optional) Name of the design document in which the index will be created.
        "name":"index2",
        "type":"json"
    }

    {
        "index":{
            "fields":["owner", "color", "size"] // Names of the fields to be queried
        },
        "ddoc":"index3Doc", // (optional) Name of the design document in which the index will be created.
        "name":"index3",
        "type":"json"
    }
    ```

    - Each index definition has its own `ddoc` value, following the CouchDB recommended practice.
- In general, you should model index fields to match the fields that will be used in query filters and sorts. 
- Fabric takes care of indexing the documents in the database using a pattern called *index warming*. CouchDB does not typically index new or updated documents until the next query. Fabric ensures that indexes stay ‘warm’ by requesting an index update after every block of data is committed. This ensures queries are fast because they do not have to index documents before running the query. This process keeps the index current and refreshed every time new records are added to the state database.
    - If your chaincode installation and instantiation uses the Hyperledger Fabric Node SDK, the JSON index files can be located in any folder as long as it conforms to this [ ] directory structure. During the chaincode installation using the `client.installChaincode()` API, include the attribute (`metadataPath`) in the installation request. The value of the `metadataPath` is a string representing the **absolute path** to the directory structure containing the JSON index file(s).
    - If you are using the `peer` commands to install and instantiate the chaincode, then the JSON index files must be located under the path `META-INF/statedb/couchdb/indexes` which is located inside the directory where the chaincode resides.
- Verify index was deployed
	
    ```bash
    docker logs peer0.org1.example.com  2>&1 | grep "CouchDB index"                              (work-1.4.1-beta1-yx|✚5)
    # 2020-01-06 02:45:09.949 UTC [couchdb] CreateIndex -> INFO 06f Created CouchDB index [indexTxFlow] in state database [mychannel_mycc] using design document [_design/indexTxFlowDoc]
    ```

- Specifying an index name on a query is optional. If not specified, and an index already exists for the fields being queried, the existing index will be automatically used.
    - It is a good practice to explicitly include an index name on a query using the `use_index` keyword. Without it, CouchDB may pick a less optimal index.
    - Also CouchDB may not use an index at all and you may not realize it, at the low volumes during testing. Only upon higher volumes you may realize slow performance because CouchDB is not using an index and you assumed it was.
- After an index has been deployed during chaincode instantiation, it will automatically be utilized by chaincode queries. CouchDB can determine which index to use based on the fields being queried. If an index exists for the query criteria it will be used.
	
    ```bash
    # Rich Query with both the design doc name indexOwnerDoc and index name indexOwner explicitly specified
    peer chaincode query -C $CHANNEL_NAME -n marbles -c '{"Args":["queryMarbles", "{\"selector\":{\"docType\":\"marble\",\"owner\":\"tom\"}, \"use_index\":[\"_design/indexOwnerDoc\", \"indexOwner\"]}"]}'

    # Query Result: [{"Key":"marble1", "Record":{"color":"blue","docType":"marble","name":"marble1","owner":"tom","size":35}}]
    ```

    - With CouchDB, if you plan to explicitly include the index name on the query, then the index definition must include the `ddoc` value, so it can be referenced with the `use_index` keyword.
- Remember the following when writing your queries:
    - ***All fields*** in the index must also be in the selector or sort sections of your query for the index to be used.
    - More complex queries will have a lower performance and will be less likely to use an index.
    - You should try to avoid operators that will result in a full table scan or a full index scan such as `$or`, `$in` and `$regex`.
	
    ```bash
    # {"index":{"fields":["docType","owner"]},"ddoc":"indexOwnerDoc", "name":"indexOwner","type":"json"}

    # Example one: query fully supported by the index
    peer chaincode query -C $CHANNEL_NAME -n marbles -c '{"Args":["queryMarbles", "{\"selector\":{\"docType\":\"marble\",\"owner\":\"tom\"}, \"use_index\":[\"indexOwnerDoc\", \"indexOwner\"]}"]}'

    # Example two: query fully supported by the index with additional data
    peer chaincode query -C $CHANNEL_NAME -n marbles -c '{"Args":["queryMarbles", "{\"selector\":{\"docType\":\"marble\",\"owner\":\"tom\",\"color\":\"red\"}, \"use_index\":[\"/indexOwnerDoc\", \"indexOwner\"]}"]}'

    # Example three: query not supported by the index
    peer chaincode query -C $CHANNEL_NAME -n marbles -c '{"Args":["queryMarbles", "{\"selector\":{\"owner\":\"tom\"}, \"use_index\":[\"indexOwnerDoc\", \"indexOwner\"]}"]}'
    ```

    - If you add extra fields to the query above, it will still use the index. However, the query will additionally have to scan the indexed data for the extra fields, resulting in a longer response time.
    - A query that does not include all fields in the index will have to scan the full database instead.
- In general, more complex queries will have a longer response time, and have a lower chance of being supported by an index.
	
    ```bash
    # Example four: query with $or supported by the index
    peer chaincode query -C $CHANNEL_NAME -n marbles -c '{"Args":["queryMarbles", "{\"selector\":{"\$or\":[{\"docType\:\"marble\"},{\"owner\":\"tom\"}]}, \"use_index\":[\"indexOwnerDoc\", \"indexOwner\"]}"]}'

    // Example five: a complex query not supported by the index
    peer chaincode query -C $CHANNEL_NAME -n marbles -c '{"Args":["queryMarbles", "{\"selector\":{"\$or\":[{\"docType\":\"marble\",\"owner\":\"tom\"},{"\color\":"\yellow\"}]}, \"use_index\":[\"indexOwnerDoc\", \"indexOwner\"]}"]}'
    ```

    - Query four will still use the index because it searches for fields that are included in `indexOwnerDoc`. However, the `$or` condition in the query requires a scan of all the items in the index, resulting in a longer response time.
    - Query five searches for all marbles owned by tom or any other items that are yellow. This query will not use the index because it will need to **search the entire table** to meet the `$or` condition.
        - Depending the amount of data on your ledger, this query will take a long time to respond or may timeout.
- Using indexes is not a solution for collecting large amounts of data. The blockchain data structure is optimized to validate and confirm transactions and is not suited for data analytics or reporting. 
- [Off chain data sample](https://github.com/hyperledger/fabric-samples/tree/master/off_chain_data)
- When large result sets are returned by CouchDB queries, a set of APIs is available which can be called by chaincode to paginate the list of results. Pagination provides a mechanism to partition the result set by specifying a pagesize and a start point – a bookmark which indicates where to begin the result set. The client application iteratively invokes the chaincode that executes the query until no more results are returned. 
	
    ```bash
    # Rich Query with index name explicitly specified and a page size of 3:
    peer chaincode query -C $CHANNEL_NAME -n marbles -c '{"Args":["queryMarblesWithPagination", "{\"selector\":{\"docType\":\"marble\",\"owner\":\"tom\"}, \"use_index\":[\"_design/indexOwnerDoc\", \"indexOwner\"]}","3",""]}'
    # [{"Key":"marble1", "Record":{"color":"blue","docType":"marble","name":"marble1","owner":"tom","size":35}},
    # {"Key":"marble2", "Record":{"color":"yellow","docType":"marble","name":"marble2","owner":"tom","size":35}},
    # {"Key":"marble3", "Record":{"color":"green","docType":"marble","name":"marble3","owner":"tom","size":20}}]
    # [{"ResponseMetadata":{"RecordsCount":"3",
    # "Bookmark":"g1AAAABLeJzLYWBgYMpgSmHgKy5JLCrJTq2MT8lPzkzJBYqz5yYWJeWkGoOkOWDSOSANIFk2iCyIyVySn5uVBQAGEhRz"}}]

    # peer chaincode query -C $CHANNEL_NAME -n marbles -c '{"Args":["queryMarblesWithPagination", "{\"selector\":{\"docType\":\"marble\",\"owner\":\"tom\"}, \"use_index\":[\"_design/indexOwnerDoc\", \"indexOwner\"]}","3","g1AAAABLeJzLYWBgYMpgSmHgKy5JLCrJTq2MT8lPzkzJBYqz5yYWJeWkGoOkOWDSOSANIFk2iCyIyVySn5uVBQAGEhRz"]}'
    ```

    - When no bookmark is specified, the query starts with the “first” page of records.
    - Bookmarks are uniquely generated by CouchDB for each query and represent a placeholder in the result set. Pass the returned bookmark on the subsequent iteration of the query to retrieve the next set of results.
- In order for an index to be updated, the original index definition must have included the design document **`ddoc` attribute and an index name**. 
- To update an index definition, use the same index name but alter the index definition. Simply edit the index JSON file and add or remove fields from the index. 
    - Fabric only supports the index type JSON, changing the index type is not supported. 
    - The updated index definition gets redeployed to the peer’s state database when the chaincode is installed and instantiated. 
    - Changes to the index name or `ddoc` attributes will result in a new index being created and the original index remains unchanged in CouchDB until it is removed.
- If the state database has a significant volume of data, it will take some time for the index to be re-built, during which time chaincode invokes that issue queries may fail or timeout.
- If you have access to your peer’s CouchDB state database in a development environment, you can iteratively test various indexes in support of your chaincode queries. Any changes to chaincode though would require redeployment. 
    - Use the [CouchDB Fauxton interface](http://docs.couchdb.org/en/latest/fauxton/index.html) or a command line `curl` utility to create and update indexes.

        ```bash
        # http://localhost:5984/_utils
        curl -i -X POST -H "Content-Type: application/json" -d
            "{\"index\":{\"fields\":[\"docType\",\"owner\"]},
            \"name\":\"indexOwner\",
            \"ddoc\":\"indexOwnerDoc\",
            \"type\":\"json\"}" http://localhost:5984/mychannel_marbles/_index
        ```

- Index deletion is not managed by Fabric tooling. If you need to delete an index, manually issue a curl command against the database or delete it using the Fauxton interface.

    ```bash
    curl -X DELETE http://localhost:5984/{database_name}/_index/{design_doc}/json/{index_name} -H  "accept: */*" -H  "Host: localhost:5984"

    curl -X DELETE http://localhost:5984/mychannel_marbles/_index/indexOwnerDoc/json/indexOwner -H  "accept: */*" -H  "Host: localhost:5984"
    ```
