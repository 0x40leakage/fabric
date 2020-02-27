- [ ] peer, orderer, kafka 需挂载出来的目录（10G 限制），个目录用途
- [ ] CORE_CHAINCODE_BUILDER (fabric-ccenv), CORE_CHAINCODE_GOLANG_RUNTIME (fabric-baseos) 这两项配置未指定，如何找到对应的镜像
- [ ] 查看安装好的 cc 的背书策略
- [ ] orderer 启动后如何确定共识模式？从哪里找 kafka 来链接（创世块？）
    - CONFIGTX_ORDERER_ORDERERTYPE=kafka
    - CONFIGTX_ORDERER_KAFKA_BROKERS=[10.10.60.50:9092,10.10.60.50:9093,10.10.60.51:9092,10.10.60.51:9093]
- [ ] cc 初始化只需要在一个 peer 上执行是因为初始化的交易在所有 peer 上都有，还是在 orderer 上的 channel 配置里
- [ ] peer 怎么知道其它 peer 的信息并与之连接
---
- [ ] 通过openssl来生成证书，先生成一个自签名的ca证书，然后用ca证书签发其他各个证书，由于fabric使用signcert的hash来查找keystore里对应的私钥，所以采用此方法需要计算这些hash值并重命名keystore里的值。过程较繁琐，不建议采用。
- [ ] 所有的users都必须包含一个Admin证书，用来进行权限控制。
    admincerts：因为在fabric1.0不同的角色有不同的权限控制，所以admincerts可以指定admin拥有哪些权限。
    1) cacerts：cacerts是指证书的签发机构的证书。在节点间通信时，当采用tls模式，fabric会要求验证请求者（包含sdk或其他节点）的签发机构证书是否在本节点要求的（在创建链时可以指定）签发机构内，如果不在，则不可与本节点通信。
    2) keystore：对应私钥的位置。
    3) signcerts：signcert是指颁发给节点或者用户的证书，用以验证节点或者用户的签名。当peer节点或者orderer节点对transaction或者block签名后，其他的peer节点或orderer节点需要对签名进行验证，就需要利用signcert里的证书进行验证。
    4) tlscacerts：当节点之间用tls加密通信时放置tls的ca cert。
- [ ] 部署手册 configtx.yaml 解析