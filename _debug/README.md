
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
docker-compose -f docker-compose-cli-raft-native-3-orderers.yaml up -d
docker exec cli scripts/script.sh mychannel 3 golang 10 false


docker-compose -f docker-compose-cli-raft-native-3-orderers.yaml down -v
./byfn.sh down
sudo rm -rf ../orderer/orderer-data/* 


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
# 3 native raft orderes, 1 native peer, 3 dockerized peers

# /etc/hosts 加 peer0.org1.example.com 等到 127.0.0.1 的映射

# github.com/hyperledger/fabric/_debug/first-network
docker-compose -f docker-compose-cli-raft-native-3-orderers-1-peer.yaml up -d
# ./scripts/script-1-native-peer.sh mychannel 3 golang 10 false
```

- [ ] 关闭 `gossip.discovery` 报错，考虑先关闭 discovery 服务



---

https://chai2010.cn/advanced-go-programming-book/ch4-rpc/ch4-08-grpcurl.html

https://yq.aliyun.com/articles/740152?spm=a2c4e.11155435.0.0.42576ac1yT0Ffp  
https://www.jianshu.com/p/dbed4e210956?spm=a2c4e.10696291.0.0.6fd019a43RbjSU  

https://stackoverflow.com/questions/62495170/hyperledger-fabric-serverhandshake-tls-handshake-bad-certificate-server-peerser

Error: Error endorsing chaincode: rpc error: code = Unavailable desc = all SubConns are in TransientFailure, latest connection error: <nil>


export FABRIC_CFG_PATH=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/sampleconfig
export CORE_PEER_TLS_KEY_FILE=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=10.0.0.111:7051
./peer chaincode install -n mycc -v 2.0 -l golang -p github.com/hyperledger/fabric/_debug/chaincode/chaincode_example02/go

export FABRIC_CFG_PATH=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/sampleconfig
export CORE_PEER_TLS_KEY_FILE=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
./peer chaincode install -n mycc -v 3.0 -l golang -p github.com/hyperledger/fabric/_debug/chaincode/chaincode_example02/go

export FABRIC_CFG_PATH=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/sampleconfig
export CORE_PEER_TLS_KEY_FILE=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
./peer chaincode install -n mycc -v 4.0 -l golang -p github.com/hyperledger/fabric/_debug/chaincode/chaincode_example02/go

export FABRIC_CFG_PATH=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/sampleconfig
export CORE_PEER_TLS_KEY_FILE=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=127.0.0.1:7051
./peer chaincode install -n mycc -v 5.0 -l golang -p github.com/hyperledger/fabric/_debug/chaincode/chaincode_example02/go

export FABRIC_CFG_PATH=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/sampleconfig
export CORE_PEER_TLS_KEY_FILE=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=172.17.0.1:7051







export FABRIC_CFG_PATH=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/sampleconfig
export CORE_PEER_MSPCONFIGPATH=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_TLS_ROOTCERT_FILE=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_TLS_KEY_FILE=/home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key


./peer channel create -o orderer0.example.com:7050 -c mychannel -f ../_debug/first-network/channel-artifacts/channel.tx --tls true --cafile /home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

./peer channel join -b ../_debug/first-network/channel-artifacts/mychannel.block
./peer channel join -b ./mychannel.block
<!-- 2021-02-01 10:49:45.294 UTC [core.comm] ServerHandshake -> ERRO 06c Server TLS handshake failed in 174.908µs with error tls: first record does not look like a TLS handshake server=Orderer remoteaddress=127.0.0.1:59702 -->

./peer chaincode install -n mycc -v 6.0 -l golang -p github.com/hyperledger/fabric/_debug/chaincode/chaincode_example02/go

./peer chaincode instantiate -o orderer0.example.com:7050 --tls true --cafile /home/ubuntu/go/src/github.com/hyperledger/fabric/_debug/first-network/crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc -l golang -v 3.0 -c '{"Args":["init","a","100","b","200"]}' -P 'OR ('\''Org1MSP.peer'\'','\''Org2MSP.peer'\'')'




peer channel create -o orderer0.example.com:7050 -c mychannel -f ./channel-artifacts/channel.tx --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
peer channel join -b ./mychannel.block
peer chaincode install -n mycc -v 6.0 -l golang -p github.com/chaincode/chaincode_example02/go
peer chaincode instantiate -o orderer0.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc -l golang -v 6.0 -c '{"Args":["init","a","100","b","200"]}' -P 'OR ('\''Org1MSP.peer'\'','\''Org2MSP.peer'\'')'