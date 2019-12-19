<!-- https://blog.csdn.net/idsuf698987/article/details/75388868 -->

- `peer node start` 执行的函数 `serve`
	
    ```go
    func serve(args []string) error {
        ledgermgmt.Initialize()
        // ...
    }
    ```

- 账本源码：`common/ledger`，`core/ledger`。
- Fabric 中的 ledger 就是一系列数据库存储操作，对应所选用的数据库，主要有两种: `goleveldb` 和 `couchDB`，默认选用 `goleveldb`。（`core.yaml`-`ledger.stateDatabase`）
    - `goleveldb` 主要使用 `github.com/syndtr/goleveldb/leveldb` 库。
    - `leveldb` 的操作的代码集中在 `common/ledger/util/leveldbhelper` 目录下。
    - couchDB 源码集中在 `core/ledger/util/couchdb` 下。
- `leveldb` 基本操作
	
    ```go
    // 在当前目录下创建一个 db 文件夹作为数据库的目录
    db, err := levendb.OpenFile("./db", nil)

    // 存储键值
    db.Put([]byte("key1"), []byte("value1"), nil)
    // 读取
    data,_ := db.Get([]byte("key1"), nil)

    // 遍历数据库
    iter := db.NewIterator(nil, nil)
    for iter.Next(){ 
        fmt.Printf("key=%s,value=%s\n",iter.Key(),iter.Value()) 
    }
    // 释放迭代器
    iter.Release()

    // 关闭数据库
    db.Close()
    ```

- `ledgermgmt.Initialize()`
	
    ```go
    // core/ledger/ledgermgmt/ledger_mgmt.go
    once.Do(func() {
		initialize()
    })
    
    // initialize() 初始化 3 个全局变量
    initialized = true
    openedLedgers = make(map[string]ledger.PeerLedger) // 分配内存

    // 返回 PeerLedgerProvider 接口的一个具体实现 (type Provider)
    provider, err := kvledger.NewProvider()
    ledgerProvider = provider

    // NewProvider instantiates a new Provider.
    func NewProvider() (ledger.PeerLedgerProvider, error) {
        logger.Info("Initializing ledger provider")
        // Initialize the ID store (inventory of chainIds/ledgerIds)
        idStore := openIDStore(ledgerconfig.GetLedgerProviderPath())
        ledgerStoreProvider := ledgerstorage.NewProvider()
        // Initialize the history database (index for history of values by key)
        historydbProvider := historyleveldb.NewHistoryDBProvider()
        logger.Info("ledger provider Initialized")
        provider := &Provider{idStore, ledgerStoreProvider,
            nil, historydbProvider, nil, nil, nil, nil, nil, nil}
        return provider, nil
    }

    // PeerLedgerProvider provides handle to ledger instances
    type PeerLedgerProvider interface {
        // Create creates a new ledger with the given genesis block.
        // This function guarantees that the creation of ledger and committing the genesis block would an atomic action
        // The chain id retrieved from the genesis block is treated as a ledger id
        Create(genesisBlock *common.Block) (PeerLedger, error)
        // Open opens an already created ledger
        Open(ledgerID string) (PeerLedger, error)
        // Exists tells whether the ledger with given id exists
        Exists(ledgerID string) (bool, error)
        // List lists the ids of the existing ledgers
        List() ([]string, error)
        // Close closes the PeerLedgerProvider
        Close()
    }

    // Provider implements interface ledger.PeerLedgerProvider
    type Provider struct {
        idStore             *idStore // ledgerID 数据库
        ledgerStoreProvider *ledgerstorage.Provider // block 数据库存储服务对象
        vdbProvider         privacyenabledstate.DBProvider // 状态数据库存储服务对象
        historydbProvider   historydb.HistoryDBProvider // 历史数据库存储服务对象
        configHistoryMgr    confighistory.Mgr
        stateListeners      []ledger.StateListener
        bookkeepingProvider bookkeeping.Provider
        initializer         *ledger.Initializer
        collElgNotifier     *collElgNotifier
        stats               *stats
    }
    ```

    - 根据 Fabric 惯例，在每个定义对象结构的文件里，通常都会有一个专门用于生成该对象的函数， `kvledger.NewProvider()` 即用于生成键值账本服务提供者的函数。`Provider` 中的 4 个成员对象就是 4 个数据库，分别用于存储不同的数据，`kvledger.NewProvider()` 分别按照配置生成这 4 个数据库对象。
    - `idStore` 和 `blockStoreProvider` 有自己特殊的配置，其余 2 个使用 leveldb 作为数据库存储服务提供者。
## 块数据库存储服务对象
- `blockStoreProvider` 代码集中在 `commom/ledger/blkstorage`
	
    ```go
    type Provider struct {
        blkStoreProvider     blkstorage.BlockStoreProvider
        // Provider provides handle to specific Store that in turn manages private write sets for a ledger
        pvtdataStoreProvider pvtdatastorage.Provider
    }

    // commom/ledger/blkstorage/blockstorage.go
    // BlockStoreProvider provides an handle to a BlockStore
    type BlockStoreProvider interface {
        CreateBlockStore(ledgerid string) (BlockStore, error)
        OpenBlockStore(ledgerid string) (BlockStore, error)
        Exists(ledgerid string) (bool, error)
        List() ([]string, error)
        Close()
    }

    // FsBlockstoreProvider 实现了 BlockStoreProvider 接口
    // FsBlockstoreProvider provides handle to block storage - this is not thread-safe
    type FsBlockstoreProvider struct {
        conf            *Conf
        indexConfig     *blkstorage.IndexConfig
        leveldbProvider *leveldbhelper.Provider
    }
    ```

    - 与块数据存储服务对象 `blockStoreProvider` 最终对接的是 3 个成员，其中 2 个配置项成员 `conf` 和 `indexConfig`，是相较于其他数据库服务对象所独有的，一个 `leveldb` 数据库存储服务提供者 `leveldbProvider`，则和其他数据库服务对象一样，用于初始化 `FsBlockstoreProvider` 的函数即为 `fsblkstorage.NewProvider()`。
    - ![](https://img-blog.csdn.net/20170719152102499?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvaWRzdWY2OTg5ODc=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)
- `kvledger.NewProvider()`
	
    ```go
    // Initialize the block storage
    // 初始化 blockStoreProvider 对象
	attrsToIndex := []blkstorage.IndexableAttr{
		blkstorage.IndexableAttrBlockHash,
		blkstorage.IndexableAttrBlockNum,
		blkstorage.IndexableAttrTxID,
		blkstorage.IndexableAttrBlockNumTranNum,
		blkstorage.IndexableAttrBlockTxID,
		blkstorage.IndexableAttrTxValidationCode,
    }
	indexConfig := &blkstorage.IndexConfig{AttrsToIndex: attrsToIndex}
	blockStoreProvider := fsblkstorage.NewProvider(
		fsblkstorage.NewConf(ledgerconfig.GetBlockStorePath(), ledgerconfig.GetMaxBlockfileSize()),
        indexConfig)

    // GetMaxBlockfileSize returns maximum size of the block file
    func GetMaxBlockfileSize() int {
        return 64 * 1024 * 1024
    }
    ```

    - `indexConfig` 是为数据库表中哪些字段建立索引的配置。
    - `conf` 对象在 `fsblkstorage/config` 中定义，两个字段 `blockStorageDir` 和 `maxBlockfileSize` 指定了块数据库存储服务对象所使用的路径和存储文件的大小 (64M, 64 * 1024 * 1024)。
        - `core.yaml`, `fileSystemPath: /var/hyperledger/production`
- 最终操作数据库数据的对象在 `common/ledger/util/leveldbhelper/leveldb_provider.go` 中定义。
	
    ```go
    // Provider enables to use a single leveldb as multiple logical leveldbs
    type Provider struct {
        db        *DB
        dbHandles map[string]*DBHandle
        mux       sync.Mutex
    }

    // 最终被初始化在 chains/index 下
    // NewProvider constructs a filesystem based block store provider
    func NewProvider(conf *Conf, indexConfig *blkstorage.IndexConfig) blkstorage.BlockStoreProvider {
        p := leveldbhelper.NewProvider(&leveldbhelper.Conf{DBPath: conf.getIndexDir()})
        return &FsBlockstoreProvider{conf, indexConfig, p}
    }
    ```

    - `leveldb` 数据库存储服务对象包含了封装 `leveldb` 数据库对象的 `db`，一个数据库映射 `dbHandles`和 `mux`。
## 其它数据库存储服务对象
- 其他几个数据库的初始化过程和块数据库存储服务对象类似，但更简单一些，基本都只是用专用函数初始化了一个 `leveldb` 数据库存储服务对象。
- 对象结构
    ![](https://img-blog.csdn.net/20170719151329525?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvaWRzdWY2OTg5ODc=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)
- 目录结构
	
    ```bash
    # peer 实例 /var/hyperledger/production（core.yaml: fileSystemPath: /var/hyperledger/production）
    ledgersData
        ledgerProvider # ledgerID 数据库
        chains # block 块存储数据库目录 
            index
            chains
                账本 ID1
                账本 ID2
                ...
        stateLeveldb   # 状态数据库目录
        historyLeveldb # 历史数据库目录
    ```

- `kvledger.NewProvider()` 函数中接近结尾的地方，有一句 `provider.recoverUnderConstructionLedger()`，该句调用了账本服务对象的一个函数，主要是用于恢复处理一些之前账本初始化失败的操作。