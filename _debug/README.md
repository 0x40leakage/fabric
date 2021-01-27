
```bash
# github.com/hyperledger/fabric
make configtxlator && make cryptogen && make configtxgen

# github.com/hyperledger/fabric/_debug/first-network
./byfn down
./byfn up
```

orderer:

```bash
# https://yq.aliyun.com/articles/739846

# /etc/hosts 加 orderer0.example.com 等到 127.0.0.1 的映射
# github.com/hyperledger/fabric/_debug/first-network
./byfn.sh generate -o etcdraft 

# github.com/hyperledger/fabric/_debug/first-network
docker-compose -f docker-compose-cli-raft-native-orderer.yaml up -d



# https://hyperledger-fabric.readthedocs.io/en/release-1.4/build_network.html#create-join-channel

# 创建通道
# github.com/hyperledger/fabric/_debug/peer/bin
export FABRIC_CFG_PATH=/Users/slackbuffer/go/src/github.com/hyperledger/fabric/_debug/sampleconfig
export CORE_PEER_MSPCONFIGPATH=/Users/slackbuffer/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/Users/slackbuffer/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CHANNEL_NAME=mychannel
./peer0 channel create -o orderer0.example.com:7050 -c $CHANNEL_NAME -f /Users/slackbuffer/go/src/github.com/hyperledger/fabric/_debug/first-network/channel-artifacts/channel.tx --tls --cafile /Users/slackbuffer/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

peer:

```bash
# /etc/hosts 加 peer0.org1.example.com 等到 127.0.0.1 的映射

# github.com/hyperledger/fabric/_debug/first-network
docker-compose -f docker-compose-cli-raft-native-peerNorderer.yaml up -d
```

- [ ] 关闭 `gossip.discovery` 报错，考虑先关闭 discovery 服务