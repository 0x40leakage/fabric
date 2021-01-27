
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
```

peer:

```bash
# /etc/hosts 加 peer0.org1.example.com 等到 127.0.0.1 的映射

# github.com/hyperledger/fabric/_debug/first-network
docker-compose -f docker-compose-cli-raft-native-peerNorderer.yaml up -d
```