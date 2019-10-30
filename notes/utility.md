# chaintool
- A Fabric **chaincode compiler**.
    - Compile chaincode inside fabric-ccenv container.
- https://fabric-chaintool.readthedocs.io/en/latest/
- https://github.com/hyperledger/fabric-chaintool
# configtxlator
- https://hyperledger-fabric.readthedocs.io/en/latest/commands/configtxlator.html
# fabric-baseimage
- 基于 `fabric-baseimage` 编译出 orderer, peer, gotools, cryptogen, configtxgen, 二进制
    - [ ] ccenv-image
    - [ ] tool 镜像
# fabric-baseos
- 基于 `fabric-baseos` 编 orderer, peer 镜像
# fabric-ccenv
- The `fabric-ccenv` image is used to **build chaincode**.
    - The `fabric-ccenv` image currently includes the github.com/hyperledger/fabric/core/chaincode/shim (“shim”) package. This is convenient, as it provides the ability to package chaincode without the need to include the “shim”. However, this may cause issues in future releases (and/or when trying to use packages which are included by the “shim”).
    - In order to avoid any issues, users are advised to manually vendor the “shim” package with their chaincode prior to using the peer CLI for packaging and/or for installing chaincode.
    - Please refer to https://jira.hyperledger.org/browse/FAB-5177 for more details, and kindly be aware that given the above, we may end up changing the `fabric-ccenv` in the future.
    - > https://hyperledger-fabric.readthedocs.io/en/release-1.1/releases.html#known-issues-workarounds