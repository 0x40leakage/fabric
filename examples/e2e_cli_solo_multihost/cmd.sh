[ ] peer join channel 发送哪个节点处理
[ ] peer 如何知道 orderer 的信息，yaml 里没有
[ ] instantiate policy
[x] solo 可否多个 orderer：solo 指 orderer 为单节点，整个集群一个 orderer

# cat /etc/*-release
# sudo /sbin/route del -net 192.168.64.0 netmask 255.255.240.0
# hostname -I

[x] 0.0.0.0:7051-7053->7051-7053/tcp 提取公因数
[x] 0.0.0.0:8051->7051/tcp, 0.0.0.0:8052->7052/tcp, 0.0.0.0:8053->7053/tcp
[x] change peer, orderer log level: CORE_LOGGING_LEVEL=DEBUG ORDERER_GENERAL_LOGLEVEL=debug


# host1: peer0.org1, peer1.org1, cli
# host2: peer0.org2, peer1.org2, orderer

# on host
./generateArtifacts.sh mychannel

export HOST1_IP=10.0.0.160
export HOST2_IP=10.0.0.186


# inside cli
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

peer channel create -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/channel.tx --tls true --cafile $ORDERER_CA

# 执行前确认 CORE_PEER 环境变量 已更改
peer channel join -b mychannel.block

peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02


# 发送给 orderer 处理
peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile $ORDERER_CA -C mychannel -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR('Org1MSP.member','Org2MSP.member')"

peer chaincode invoke -o orderer.example.com:7050  --tls true --cafile $ORDERER_CA -C mychannel -n mycc -c '{"Args":["invoke","a","b","10"]}'

# 确认对应的 peer 已经 join channel
peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'




# peer0.org1
CORE_PEER_LOCALMSPID="Org1MSP" 
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt 
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp 
CORE_PEER_ADDRESS=peer0.org1.example.com:7051

# peer1.org1
CORE_PEER_LOCALMSPID="Org1MSP" 
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt 
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp 
CORE_PEER_ADDRESS=peer1.org1.example.com:7051

# CORE_PEER_ADDRESS=peer1.org1.example.com:8051 #

# peer0.org2
CORE_PEER_LOCALMSPID="Org2MSP" 
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt 
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp 
CORE_PEER_ADDRESS=peer0.org2.example.com:9051

# peer1.org2
CORE_PEER_LOCALMSPID="Org2MSP" 
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt 
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp 
CORE_PEER_ADDRESS=peer1.org2.example.com:10051

# peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
# 2019-12-05 02:18:03.774 UTC [msp] GetLocalMSP -> DEBU 001 Returning existing local MSP
# 2019-12-05 02:18:03.774 UTC [msp] GetDefaultSigningIdentity -> DEBU 002 Obtaining default signing identity
# 2019-12-05 02:18:03.774 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 003 Using default escc
# 2019-12-05 02:18:03.774 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 004 Using default vscc
# 2019-12-05 02:18:03.775 UTC [msp/identity] Sign -> DEBU 005 Sign: plaintext: 0A91070A6708031A0C08DBD1A1EF0510...6D7963631A0A0A0571756572790A0161
# 2019-12-05 02:18:03.775 UTC [msp/identity] Sign -> DEBU 006 Sign: digest: E3DC361DF61272A1EF7FA5FDB24C79384F21AB21825ED5BC2D74046F7F379AB3
# Error: Error endorsing query: rpc error: code = Unknown desc = Failed to deserialize creator identity, err MSP Org2MSP is unknown - <nil>

# 未加入 channel 引起
# peer channel list
# 2019-12-05 02:48:53.156 UTC [channelCmd] list -> INFO 006 Channels peers has joined to: # 空

# 2019-12-05 02:49:43.896 UTC [channelCmd] list -> INFO 006 Channels peers has joined to:
# 2019-12-05 02:49:43.896 UTC [channelCmd] list -> INFO 007 mychannel