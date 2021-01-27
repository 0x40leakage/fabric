
```bash
# github.com/hyperledger/fabric
make configtxlator && make cryptogen && make configtxgen

# github.com/hyperledger/fabric/_debug/first-network
./byfn down
./byfn up
```

orderer:

```bash
# /etc/hosts 加 orderer0.example.com 等到 127.0.0.1 的映射
# github.com/hyperledger/fabric/_debug/first-network
./byfn.sh generate -o etcdraft 
```