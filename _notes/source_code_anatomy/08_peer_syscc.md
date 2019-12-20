<!-- https://blog.csdn.net/idsuf698987/article/details/76130699 -->

- `scc.RegisterSysCCs()`
- 系统链码的核心代码在 `fabric/core/common/sysccprovider` 和 `fabric/core/scc`下。
- Lifecycle system chaincode (LSCC) runs in all peers to handle package signing, install, instantiate, and upgrade chaincode requests. You can read more about the LSCC implements this [process](https://hyperledger-fabric.readthedocs.io/en/release-1.4/chaincode4noah.html#chaincode-lifecycle).
- Configuration system chaincode (CSCC) runs in all peers to handle changes to a channel configuration, such as a policy update. You can read more about this process in the following chaincode [topic](https://hyperledger-fabric.readthedocs.io/en/release-1.4/configtx.html#configuration-updates).
- Query system chaincode (QSCC) runs in all peers to provide ledger APIs which include block query, transaction query etc. You can read more about these ledger APIs in the transaction context [topic](https://hyperledger-fabric.readthedocs.io/en/latest/developapps/transactioncontext.html).
- Endorsement system chaincode (ESCC) runs in endorsing peers to cryptographically sign a transaction response. You can read more about how the ESCC implements this [process](https://hyperledger-fabric.readthedocs.io/en/release-1.4/peers/peers.html#phase-1-proposal).
- Validation system chaincode (VSCC) validates a transaction, including checking endorsement policy and read-write set versioning. You can read more about the LSCC implements this [process](https://hyperledger-fabric.readthedocs.io/en/release-1.4/peers/peers.html#phase-3-validation-and-commit).
- > https://hyperledger-fabric.readthedocs.io/en/release-1.4/smartcontract/smartcontract.html#system-chaincode
- 预定义和注册
	
    ```go
    var systemChaincodes = []*SystemChaincode{

    // RegisterSysCCs is the hook for system chaincodes where system chaincodes are registered with the fabric
    // note the chaincode must still be deployed and launched like a user chaincode will be
    func RegisterSysCCs() {
        for _, sysCC := range systemChaincodes {
            RegisterSysCC(sysCC)
        }
    }

    // Register registers system chaincode with given path. The deploy should be called to initialize
    func Register(path string, cc shim.Chaincode) error {
        tmp := typeRegistry[path]
        if tmp != nil {
            return SysCCRegisteredErr(path)
        }
        typeRegistry[path] = &inprocContainer{chaincode: cc}
        return nil
    }
    ```
