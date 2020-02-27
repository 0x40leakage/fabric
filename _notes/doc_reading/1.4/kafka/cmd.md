# 进程启动 kafka，zk
配置zookeeper节点
切换至kafka_2.11-0.9.0.1/config目录，配置Zookeeper 节点，以zookeeper-0.properties为例。
    1）执行命令： cp zookeeper.properties zookeeper-0.properties
    2）打开zookeeper-0.propeties文件，配置zookeeper0服务
    tickTime=2000
    initLimit=5
    syncLimit=2
    dataDir=/tmp/zookeeper0/data #zookeeper0数据保存目录 *************
    dataLogDir=/tmp/zookeeper0/log
    clientPort=2181 #访问zookeeper0的端口 
    server.0=localhost:2888:3888 #server0通过2888端口与leader通讯，若无Leader，则通过3888选举leader。如果是zookeeper采用联机模式， localhost则要改成该主机的IP（如172.16.1.7）
    server.1=localhost:2889:3889 #server1通过2889端口与leader通讯，若无Leader，则通过3889选举leader。如果是zookeeper采用联机模式， localhost则要改成该主机的IP（如172.16.1.7）
    server.2=localhost:2890:3890 #server2通过2890端口与leader通讯，若无Leader，则通过3890选举leader。如果是zookeeper采用联机模式， localhost则要改成该主机的IP（如172.16.1.7）
    3）切换至/tmp/目录，创建zookeeper0/data和zookeeper0/log目录：
    执行如下命令：
    mkdir -p /tmp/zookeeper0/data
    mkdir -p /tmp/zookeeper0/log
    cd /tmp/zookeeper0/data
    echo 0 > myid
    在data目录新创建文件myid，表示该server的id为0
    4）切换至/opt/gopath/src/github.com/hyperledger/fabric/kafka_2.11-0.9.0.1目录:
    创建logs目录，mkdir logs
    执行命令: bin/zookeeper-server-start.sh config/zookeeper-0.properties > logs/zookeeper0.log & 来启动zookeeper0服务。
    5）重复执行1，2，3，4步骤来启动zookeeper1，zookeeper2服务。配置文件需根据zookeeper-0.properties来变更。
查看 zk 节点状态（leader，follower）
    echo stat | nc localhost 2181
    echo stat | nc localhost 2182
    echo stat | nc localhost 2183

配置4个kafka节点
    1）创建kafka-0节点配置文件：
    执行如下命令：
    echo $HOSTNAME
    把echo的输出加入到/etc/hosts文件中，假设输出为hostname-1，则添加如下内容：127.0.0.1 hostname-1
    完成后通过ping hostname-1来检查host有无生效，若无效，则需要网络重启。
    cd /opt/gopath/src/github.com/hyperledger/fabric/kafka_2.11-0.9.0.1/config
    根据server.properties创建kafka-0节点的配置文件，执行如下命令：
    cp server.properties server-0.properties
    2）打开server-0.properties配置文件，进行kafka节点配置。
    broker.id=0 #kafka节点编号，唯一标识一个kafka节点
    listeners=PLAINTEXT://:9092#kafka监听端口
    # The port the socket server listens on
    port=9092 #该kafka节点监听的端口
    log.dirs=/tmp/kafka-logs-0 #kafka的数据存储目录 *************
    #zookeeper.connect是zookeeper各个服务器的ip和端口。如果是采用联机模式，则需要修改localhost为对应的zookeeper服务IP，如zookeeper0部署在172.16.1.7，zookeeper1部署在172.16.1.8，zookeeper2部署在172.16.1.9服务器，那么下面的配置修改如下：            
    zookeeper.connect=172.16.1.7:2181,172.16.1.8:2182,172.16.1.9:2183
    zookeeper.connect=localhost:2181,localhost:2182,localhost:2183
    3）另外由于在多台主机上需要设置advertised.host.name(在不进行设置时，默认的设置因操作系统原因可能是本机IP也可能是localhost，为防止出错，需进行设置)，将其设置为本机IP。
       advertised.host.name=kafka_ip #kafka_ip为当前主机的IP
    4）启动kafka节点
       切换至/opt/gopath/src/github.com/hyperledger/fabric/kafka_2.11-0.9.0.1
       执行命令：bin/kafka-server-start.sh config/server-0.properties > logs/kafka-0.log &
    5）以同样的方式创建server-1.properties，server-2.properties，server-3.properties，其中broker.id分别为1,2,3，listeners后缀也都改成9093,9094,9095， port分别为9093,9094,9095，log.dirs自定义。
执行命令: echo dump | nc localhost 2183 | grep brokers，可以查看kafka节点的状态。
# docker-compose方式启动kafka节点和zookeeper节点
docker-compose zookeeper配置说明如下：
    ZOO_MY_ID：表示zookeeper的id号
    ZOO_SERVERS：表示zookeeper集群，其中zookeeper0:2888:3888 #zookeeper0通过2888端口与leader通讯，若无Leader，则通过3888选举leader。

docker-compose-kafka.yaml中kafka配置说明如下：
    KAFKA_BROKER_ID：本kafka节点的id号，必须唯一
    KAFKA_ZOOKEEPER_CONNECT:kafka节点关联的zookeeper节点（所有kafka节点配置一样）
    KAFKA_DEFAULT_REPLICATION_FACTOR # 默认分区的replication个数 ，不能大于集群中broker的个数。
    KAFKA_MIN_INSYNC_REPLICAS #指定replicas的最小数目（必须确认每一个repica的写数据都是成功的），如果这个数目没有达到，producer会产生异常。
    对于所有的kafka节点需要配置KAFKA_ADVERTISED_HOST_NAME为本物理机IP，KAFKA_ZOOKEEPER_CONNECT需要配置为前文中三个zookeeper的endpoint（ip:port）。
# 用进程方式启动orderer节点
在orderer节点对应的目录下创建orderer.yaml文件，执行如下命令：
    cd /opt/gopath/src/github.com/hyperledger/fabric/examples/e2e_cli
为orderer节点创建目录：mkdir orderer1
切换至orderer1目录，并执行如下命令：
    cp /opt/gopath/src/github.com/hyperledger/fabric/sampleconfig/orderer.yaml .
打开orderer.yaml文件，修改以下字段：
    1) 修改General.ListenPort为56050端口
    2) 修改General.GenesisMethod为file模式
    3) 修改General.GenesisFile为../orderer.block，其中orderer.block为4.4生成的创世块
    4) 修改General.LocalMSPDir为orderer节点对应的msp目录，本例为../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp
    5) 修改General.LocalMSPID为orderer节点对应的mspID，本例为OrdererMSP1
    6) 修改FileLedger.Location为orderer节点有权访问的路径，如下：                       
        var/hyperledger/production/orderer 
orderer命令在当前目录下查找配置文件orderer.yaml，并加载到内存中。
通过执行如下命令来启动orderer节点：
    ORDERER_CFG_PATH='.'  /opt/gopath/src/github.com/hyperledger/fabric/build/bin/orderer
# docker-compose方式启动orderer节点
将3.1生成的crypto-config目录和4.4生成的orderer.block拷贝到集群中各自主机上。本例中，分别拷贝到192.168.9.55:~/docker-compose-kafka目录和192.168.9.63:~/docker-compose-kafka目录下。
docker-compose-kafka.yaml中orderer节点配置说明：
    ORDERER_GENERAL_LOCALMSPDIR：docker container里对应的msp文件夹，此处不建议修改。通过volumes映射来改变msp目录，将宿主机的msp目录映射到/var/hyperledger/msp。
    ORDERER_GENERAL_LOCALMSPID：orderer节点的mspid
    ORDERER_GENERAL_LISTENADDRESS：orderer节点监听IP，不建议修改
    ORDERER_GENERAL_LISTENPORT：orderer节点监听端口
    CONFIGTX_ORDERER_ORDERERTYPE：orderer节点共识模式
    CONFIGTX_ORDERER_KAFKA_BROKERS：orderer节点连接的kafka IP和端口
    CONFIGTX_ORDERER_ADDRESSES：对应configtx.yaml文件里的orderer addresses
    ORDERER_GENERAL_GENESISFILE：对应orderer节点的创世块，此处不建议修改。通过volumes映射来改变orderer.block所在目录，将宿主机的orderer.block所在目录映射到/var/hyperledger/configs。
    ORDERER_GENERAL_TLS_ENABLED：对应是否打开tls开关，默认为false。由于fabric 1.0 release版本需要hostname验证，所以tls此处修改为false。云象正式版本会提供tls，且按照IP可访问，不需要hostname。






```bash
systemctl is-enabled docker.service
# 启动 docker (https://docs.docker.com/config/daemon/systemd/)
sudo systemctl start docker


# ========================================================================
#   启动顺序：先 zk，后 kafka
# ========================================================================
# 10.18.8.177
## 起 peer0.org1.example.com
docker-compose -f docker-compose-fabric2.yaml up -d
## 起 kafka2
docker-compose -f docker-compose-kafka2.yaml up -d
## 起 zookeeper1
docker-compose -f docker-compose-zookeeper2.yaml up -d

# 10.18.8.178
## 起 peer1.org1.example.com
docker-compose -f docker-compose-fabric3.yaml up -d
## 起 kafka3
docker-compose -f docker-compose-kafka3.yaml up -d
## 起 zookeeper2
docker-compose -f docker-compose-zookeeper3.yaml up -d
# --no-deps
# docker-compose up -d client


# query 拉起 cc，确保服务正常
curl --request POST \
  --url http://10.18.8.175:8000/projectlog/query_product \
  --header 'Cache-Control: no-cache' \
  --header 'Content-Type: application/json' \
  --data '{"ProductID": "p2"}'


# 查看 kafka，peer，orderer 容器空间占用情况（10G）
df -h
# 后期若需挂载出来，看升级文档
```

```bash
# 重启 177
## 查看 zookeeper 状态
echo stat | nc localhost 2181
## 查看 kafka 状态
echo dump | nc localhost 2181 | grep brokers

find . -type f -name docker-compose-fabric2.yaml
## 找到配置文件，进到配置文件所在目录，启动 peer0 节点
docker-compose -f docker-compose-fabric2.yaml up -d
## curl 命令拉起容器
curl --request POST \
  --url http://10.18.8.175:8000/projectlog/query_product \
  --header 'Cache-Control: no-cache' \
  --header 'Content-Type: application/json' \
  --data '{"ProductID": "p2"}'

# 178
find . -type f -name docker-compose-fabric3.yaml
# 找到配置文件，进到配置文件所在目录，启动 peer1 节点
docker-compose -f docker-compose-fabric3.yaml up -d
# curl 命令拉起容器

curl --request POST \
  --url http://10.18.13.199:8000/projectlog/add \
  --header 'Content-Type: application/json' \
  --data '{  "ProductID":"test_purpose_product_0001",  "ProductName":"A",  "ProductLog":"产品A",  "PreliminaryOpinion":"同意",  "Step":1,  "Stage":2,  "UpProductID":"zz",    "Operators":[    {      "OperatorID":"1",      "OperatorName":"操作人A",      "OperatorOrg":"组织A",      "OperatorTime":"2018-05-21 00:00:00"    },    {      "OperatorID":"1",      "OperatorName":"操作人A",      "OperatorOrg":"组织A",      "OperatorTime":"2018-05-21 00:00:00"    }  ],    "Assigns":[    {      "NominatorID":"nomi111",      "NominatorName":"指定人A",      "NominatorOrg":"组织A",      "AssignTask":"转办"    },    {      "NominatorID":"nomi2",      "NominatorName":"指定人A",      "NominatorOrg":"组织A",      "AssignTask":"转办"    }  ],  "Subscribers":[	{		"SubscriberID": "1",		"SubscriberName": "2",		"SubscriberOrg": "3",		"PhoneNum": "4",		"WechatID": "5"	}	  ],    "ServerInfo":{    "ServerID":"1",    "ServerName":"服务器A",    "ServerIP":"xxx.xxx.xxx.xxx"  },  "SystemID":"rm-test",  "Secret":1,  "DataMode":"初始化",  "StoreTime":""}'
```