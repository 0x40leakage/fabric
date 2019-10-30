- `$(patsubst pattern,replacement,text)`
    - Finds whitespace-separated words in `text` that match `pattern` and replaces them with `replacement`.
    - `pattern` may contain a ‘%’ which acts as a wildcard, matching any number of any characters within a word. If `replacement` also contains a ‘%’, the ‘%’ is replaced by the text that matched the ‘%’ in `pattern`.
        - Only the first ‘%’ in the `pattern` and `replacement` is treated this way; any subsequent ‘%’ is unchanged.
- `$(subst from,to,text)`
    - Performs a textual replacement on the text `text`: each occurrence of `from` is replaced by `to`. The result is substituted for the function call.
- `abspath`
- > https://www.gnu.org/software/make/manual/html_node/Text-Functions.html
- `$^` - The names of **all the prerequisites**, with spaces between them
- [ ] `sed`
- 没有命令的 `make` 规则下面不要加 `@echo` 来打印日志
- `make native` 和 `make docker` 都会编二进制，因 host 环境和 docker 容器的环境大概率不同，此处不加判断无差别重新编
---
- `Makefile`
    - `images/%/Dockerfile.in`
    - `gotools/Makefile`
    - `docker-env.mk`
    - `common/metadata`
    - `scripts`
    - > `make all 2>&1 | tee makefile.log`
# `make native`
- `native: peer orderer configtxgen cryptogen configtxlator`
- **Payload Definition**
## 1. `peer: build/bin/peer`
### `build/bin/peer: build/image/ccenv/$(DUMMY)`
- `build/bin/%: $(PROJECT_FILES)`

        ```bash
        mkdir -p build/bin
        build/bin/peer
        CGO_CFLAGS=" " GOBIN=/home/centos/go/src/github.com/hyperledger/fabric/build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/metadata.Version=1.0.3 -X github.com/hyperledger/fabric/common/metadata.BaseVersion=0.3.2 -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=hyperledger -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=hyperledger" github.com/hyperledger/fabric/peer
        Binary available as build/bin/peer
        ```

- Output
    - `peer` under `./build/bin`
#### `build/image/%/$(DUMMY): Makefile build/image/%/payload build/image/%/Dockerfile`

```bash
Building docker ccenv-image
docker build  -t hyperledger/fabric-ccenv build/image/ccenv
Sending build context to Docker daemon  21.14MB
        Step 1/5 : FROM hyperledger/fabric-baseimage:x86_64-0.3.2
        ---> c92d9fdee998
        Step 2/5 : COPY payload/chaintool payload/protoc-gen-go /usr/local/bin/
        ---> Using cache
        ---> 78d19721f083
        Step 3/5 : ADD payload/goshim.tar.bz2 $GOPATH/src/
        ---> Using cache
        ---> c26153a17433
        Step 4/5 : RUN mkdir -p /chaincode/input /chaincode/output
        ---> Using cache
        ---> 548ad31da9d5
        Step 5/5 : LABEL org.hyperledger.fabric.version=1.0.3       org.hyperledger.fabric.base.version=0.3.2
        ---> Using cache
        ---> b23f08c59f30
Successfully built b23f08c59f30
Successfully tagged hyperledger/fabric-ccenv:latest
docker tag hyperledger/fabric-ccenv hyperledger/fabric-ccenv:x86_64-1.0.3
touch build/image/ccenv/.dummy-x86_64-1.0.3
```

- Output
        - `hyperledger/fabric-ccenv:latest` image, `hyperledger/fabric-ccenv:x86_64-1.0.3` image
                - `chaintool`, `protoc-gen-go` under `/usr/local/bin/`; `goshim.tar.bz2` decompressed and unpacked into `$GOPATH/src/`
##### 1. `build/image/%/payload`
- Translates to
	
        ```makefile
        # payload definition
        build/image/ccenv/payload:      build/docker/gotools/bin/protoc-gen-go \
				        build/bin/chaintool \
				        build/goshim.tar.bz2
        # Try 
        # make build/image/ccenv/payload 
        ```

- `build/image/%/payload`
	
        ```bash
        Creating build/image/ccenv/payload
        mkdir -p build/image/ccenv/payload
        cp build/docker/gotools/bin/protoc-gen-go build/bin/chaintool build/goshim.tar.bz2 build/image/ccenv/payload
        ```

###### 1. `build/docker/gotools/bin/protoc-gen-go: build/docker/gotools`
- `build/docker/gotools: gotools/Makefile`

        ```bash
        mkdir -p build/docker/gotools/bin build/docker/gotools/obj

        docker run -i --rm --user=1000 
                # flags from from $(DRUN)
                -v /home/centos/go/src/github.com/hyperledger/fabric:/opt/gopath/src/github.com/hyperledger/fabric \
                -w /opt/gopath/src/github.com/hyperledger/fabric \
                # flags from build/docker/gotools
                -v /home/centos/go/src/github.com/hyperledger/fabric/build/docker/gotools:/opt/gotools \
                # gotool/Makefile at work; override work directory
                -w /opt/gopath/src/github.com/hyperledger/fabric/gotools \
                # pull if not exists. https://github.com/hyperledger/fabric-baseimage
                hyperledger/fabric-baseimage:x86_64-0.3.2 \
                # **inside baseimage container**
                make install BINDIR=/opt/gotools/bin OBJDIR=/opt/gotools/obj


                ## GOBIN: /opt/gotools/obj/gopath/bin, GOTOOLS_BIN: /opt/gotools/obj/gopath/bin/protoc-gen-go /opt/gotools/obj/gopath/bin/govendor

                make gotool.protoc-gen-go
                # make[1]: Entering directory '/opt/gopath/src/github.com/hyperledger/fabric/gotools'
                # Building github.com/golang/protobuf/protoc-gen-go -> protoc-gen-go
                # mkdir -p /opt/gotools/obj/gopath/src/github.com/golang/protobuf/
                # cp -R /opt/gopath/src/github.com/hyperledger/fabric/vendor/github.com/golang/protobuf/* /opt/gotools/obj/gopath/src/github.com/golang/protobuf
                # GOPATH=/opt/gotools/obj/gopath go install github.com/golang/protobuf/protoc-gen-go
                # make[1]: Leaving directory '/opt/gopath/src/github.com/hyperledger/fabric/gotools'

                make gotool.govendor
                # make[1]: Entering directory '/opt/gopath/src/github.com/hyperledger/fabric/gotools'
                # Building github.com/kardianos/govendor -> govendor
                # GOPATH=/opt/gotools/obj/gopath go get github.com/kardianos/govendor

                ## corresponding to make install
                # make[1]: Leaving directory '/opt/gopath/src/github.com/hyperledger/fabric/gotools'
                # mkdir -p /opt/gotools/bin
                # cp /opt/gotools/obj/gopath/bin/protoc-gen-go /opt/gotools/obj/gopath/bin/govendor /opt/gotools/bin
        ```

- Output
    - `protoc-gen-go`, `govendor` under `./build/docker/gotools/bin`
    - > `./build/docker/gotools/obj/gopath` holds the temporary `GOPATH` inside the container
    - > Volume
        - `./fabric/build/docker/gotools:/opt/gotools`
        - `./fabric:/opt/gopath/src/github.com/hyperledger`
- > Q

        ```bash
        # [x] Why is this command executed first when `make install BINDIR=/opt/gotools/bin OBJDIR=/opt/gotools/obj`?
        # $(GOBIN)/%:
        #   $(eval TOOL = ${subst $(GOBIN)/,,${@}}) # 去掉 $(GOBIN)/ 部分
        #	$(MAKE) gotool.$(TOOL)

        # install: $(GOTOOLS_BIN)
        # $(GOBIN)/% is wildcard for $(GOTOOLS_BIN)

        ## GOBIN: /opt/gotools/obj/gopath/bin, GOTOOLS_BIN: /opt/gotools/obj/gopath/bin/protoc-gen-go /opt/gotools/obj/gopath/bin/govendor


        mkdir -p build/docker/gotools/bin build/docker/gotools/obj
        docker run -it --user=1000 -v /home/centos/go/src/github.com/hyperledger/fabric:/opt/gopath/src/github.com/hyperledger/fabric -w /opt/gopath/src/github.com/hyperledger/fabric \
                -v /home/centos/go/src/github.com/hyperledger/fabric/build/docker/gotools:/opt/gotools \
                -w /opt/gopath/src/github.com/hyperledger/fabric/gotools \
                hyperledger/fabric-baseimage:x86_64-0.3.2 \
                bash

        make install BINDIR=/opt/gotools/bin OBJDIR=/opt/gotools/obj # odd command selection (with OBJDIR)
        # make gotool.protoc-gen-go
        # make[1]: Entering directory '/opt/gopath/src/github.com/hyperledger/fabric/gotools'
        # Building github.com/golang/protobuf/protoc-gen-go -> protoc-gen-go
        # make[1]: Leaving directory '/opt/gopath/src/github.com/hyperledger/fabric/gotools'
        # mkdir -p /opt/gotools/bin
        # cp /opt/gotools/obj/gopath/bin/protoc-gen-go /opt/gotools/bin

        make install OBJDIR=/opt/gotools/obj # odd command selection (with OBJDIR)
        # make gotool.protoc-gen-go
        # make[1]: Entering directory '/opt/gopath/src/github.com/hyperledger/fabric/gotools'
        # Building github.com/golang/protobuf/protoc-gen-go -> protoc-gen-go
        # make[1]: Leaving directory '/opt/gopath/src/github.com/hyperledger/fabric/gotools'
        # mkdir -p /usr/local/bin
        # cp /opt/gotools/obj/gopath/bin/protoc-gen-go /usr/local/bin
        # cp: cannot create regular file '/usr/local/bin/protoc-gen-go': Permission denied
        # Makefile:36: recipe for target 'install' failed
        # make: *** [install] Error 1

        make install BINDIR=/opt/gotools/bin
        # mkdir -p /opt/gotools/bin
        # cp /opt/gopath/src/github.com/hyperledger/fabric/gotools/build/gopath/bin/protoc-gen-go /opt/gotools/bin

        make install
        # mkdir -p /usr/local/bin
        # cp /opt/gopath/src/github.com/hyperledger/fabric/gotools/build/gopath/bin/protoc-gen-go /usr/local/bin
        # cp: cannot create regular file '/usr/local/bin/protoc-gen-go': Permission denied
        # Makefile:36: recipe for target 'install' failed
        # make: *** [install] Error 1
        ```

###### 2. `%/chaintool: Makefile`

```bash
Installing chaintool
mkdir -p build/bin
# curl -fL https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/chaintool-1.0.0/hyperledger-fabric-chaintool-1.0.0.jar > build/bin/chaintool
cp ./cached/hyperledger-fabric-chaintool-1.0.0.jar build/bin/chaintool
chmod +x build/bin/chaintool
```

- Output
        - `chaintool` under `./build/bin`
###### 3. `build/goshim.tar.bz2: $(GOSHIM_DEPS)`

```bash
Creating build/goshim.tar.bz2
@tar -jhc -C $(GOPATH)/src $(patsubst $(GOPATH)/src/%,%,$(GOSHIM_DEPS)) > $@

# GOSHIM_DEPS: ./scripts/goListFiles.sh github.com/hyperledger/fabric/core/chaincode/shim | less
# 获取 github.com/hyperledger/fabric/core/chaincode/shim 的所有依赖库

# $(patsubst $(GOPATH)/src/%,%,$(GOSHIM_DEPS)): 去掉依赖库路径的 $(GOPAHT)/src 部分

# 切换到 $(GOPATH)/src 为了可以用（没有 $(GOPAHT)/src 部分）相对路径指定依赖库的目录
        # When -C is specified, tar will change its current directory to DIR before performing any operations. When this option is used during archive creation, it is order sensitive.
```

- Output
    - `goshim.tar.bz2` under `./build`
##### 2. `build/image/%/Dockerfile: images/%/Dockerfile.in`
## 2. `orderer: build/bin/orderer`
- `build/bin/%: $(PROJECT_FILES)`
	
        ```bash
        mkdir -p build/bin
        build/bin/orderer
        CGO_CFLAGS=" " GOBIN=/home/centos/go/src/github.com/hyperledger/fabric/build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/metadata.Version=1.0.3 -X github.com/hyperledger/fabric/common/metadata.BaseVersion=0.3.2 -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=hyperledger -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=hyperledger" github.com/hyperledger/fabric/orderer
        Binary available as build/bin/orderer
        ```

- Output
    - `orderer` under `./build/bin`
## `configtxgen: build/bin/configtxgen`, `cryptogen: build/bin/cryptogen`, `configtxlator: build/bin/configtxlator`
- `build/bin/%: $(PROJECT_FILES)`
	
        ```bash
        ## go install flags specified in its own separate rule
        mkdir -p build/bin
        build/bin/configtxgen
        CGO_CFLAGS=" " GOBIN=/home/centos/go/src/github.com/hyperledger/fabric/build/bin go install -tags "nopkcs11" -ldflags "-X github.com/hyperledger/fabric/common/configtx/tool/configtxgen/metadata.Version=1.0.3" github.com/hyperledger/fabric/common/configtx/tool/configtxgen
        Binary available as build/bin/configtxgen

        mkdir -p build/bin
        build/bin/cryptogen
        CGO_CFLAGS=" " GOBIN=/home/centos/go/src/github.com/hyperledger/fabric/build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/cryptogen/metadata.Version=1.0.3" github.com/hyperledger/fabric/common/tools/cryptogen
        Binary available as build/bin/cryptogen

        mkdir -p build/bin
        build/bin/configtxlator
        CGO_CFLAGS=" " GOBIN=/home/centos/go/src/github.com/hyperledger/fabric/build/bin go install -tags "" -ldflags "-X github.com/hyperledger/fabric/common/tools/configtxlator/metadata.Version=1.0.3" github.com/hyperledger/fabric/common/tools/configtxlator
        Binary available as build/bin/configtxlator
        ```

- Output
    - `configtxgen`, `cryptogen`, `configtxlator` under `./build/bin`
# `make docker`
- `docker: $(patsubst %,build/image/%/$(DUMMY), $(IMAGES))`
        - `IMAGES = peer orderer ccenv tools kafka zookeeper`
## 1. `peer` - `build/image/%/$(DUMMY): Makefile build/image/%/payload build/image/%/Dockerfile`
- `build/image/peer/$(DUMMY): build/image/ccenv/$(DUMMY)`
    - See `make peer`
- `build/image/%/payload` translates to payload definition
- `build/image/peer/.dummy-x86_64-1.0.3: Makefile build/image/%/payload build/image/%/Dockerfile`

        ```bash
        Building docker peer-image
        docker build  -t hyperledger/fabric-peer build/image/peer
        Sending build context to Docker daemon  25.36MB
                Step 1/7 : FROM hyperledger/fabric-baseos:x86_64-0.3.2
                ---> bbcbb9da2d83
                Step 2/7 : ENV FABRIC_CFG_PATH /etc/hyperledger/fabric
                ---> Running in 9530539f02b8
                Removing intermediate container 9530539f02b8
                ---> 9afd0b8626f5
                Step 3/7 : RUN mkdir -p /var/hyperledger/production $FABRIC_CFG_PATH
                ---> Running in 1a94a2ea4f73
                Removing intermediate container 1a94a2ea4f73
                ---> 9b1b528c2228
                Step 4/7 : COPY payload/peer /usr/local/bin
                ---> 0b3f641a5cd6
                Step 5/7 : ADD  payload/sampleconfig.tar.bz2 $FABRIC_CFG_PATH
                ---> 63505661cefc
                Step 6/7 : CMD ["peer","node","start"]
                ---> Running in 82c3a23737ac
                Removing intermediate container 82c3a23737ac
                ---> 547fc5485a02
                Step 7/7 : LABEL org.hyperledger.fabric.version=1.0.3       org.hyperledger.fabric.base.version=0.3.2
                ---> Running in 5680fc50259f
                Removing intermediate container 5680fc50259f
                ---> 169bec3377a8
        Successfully built 169bec3377a8
        Successfully tagged hyperledger/fabric-peer:latest
        docker tag hyperledger/fabric-peer hyperledger/fabric-peer:x86_64-1.0.3
        touch build/image/peer/.dummy-x86_64-1.0.3
        ```

- Output
    - `hyperledger/fabric-peer:latest` image, `hyperledger/fabric-peer:x86_64-1.0.3` image
        - From `hyperledger/fabric-baseos:x86_64-0.3.2`
        - `FABRIC_CFG_PATH`: `/etc/hyperledger/fabric`
            - `/etc/hyperledger/fabric` created
            - `sampleconfig.tar.bz2` decompressed and unpacked `/etc/hyperledger/fabric`
        - `/var/hyperledger/production` created
        - `peer` (**built using `baseimage`**) in `/usr/local/bin`
        - `CMD ["peer","node","start"]`
### 1. `build/image/peer/payload`
- Translates to
	
        ```makefile
        build/image/peer/payload:       build/docker/bin/peer \
				build/sampleconfig.tar.bz2
        ```

        - Output
            - `peer`, `sampleconfig.tar.bz2` under `build/image/peer/payload`
- Then `build/image/%/payload`

        ```bash
        Creating build/image/peer/payload
        mkdir -p build/image/peer/payload
        cp build/docker/bin/peer build/sampleconfig.tar.bz2 build/image/peer/payload
        ```

#### 1. `build/docker/bin/%: $(PROJECT_FILES)`

```bash 
Building build/docker/bin/peer
mkdir -p build/docker/bin build/docker/peer/pkg
docker run -i --rm --user=1000 
        -v /home/centos/go/src/github.com/hyperledger/fabric:/opt/gopath/src/github.com/hyperledger/fabric \
        -w /opt/gopath/src/github.com/hyperledger/fabric \
        -v /home/centos/go/src/github.com/hyperledger/fabric/build/docker/bin:/opt/gopath/bin \
        -v /home/centos/go/src/github.com/hyperledger/fabric/build/docker/peer/pkg:/opt/gopath/pkg \
        hyperledger/fabric-baseimage:x86_64-0.3.2 \
        go install -ldflags "-X github.com/hyperledger/fabric/common/metadata.Version=1.0.3 -X github.com/hyperledger/fabric/common/metadata.BaseVersion=0.3.2 -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=hyperledger -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=hyperledger -linkmode external -extldflags '-static -lpthread'" github.com/hyperledger/fabric/peer
touch build/docker/bin/peer
```

- Output
    - `peer` in `build/docker/bin`
#### 2. `build/sampleconfig.tar.bz2: $(shell find sampleconfig -type f)`

```bash
(cd sampleconfig && tar -jc *) > build/sampleconfig.tar.bz2
```
## 2. `orderer` - `build/image/%/$(DUMMY): Makefile build/image/%/payload build/image/%/Dockerfile`

```bash
Building docker orderer-image
docker build  -t hyperledger/fabric-orderer build/image/orderer
Sending build context to Docker daemon  22.38MB
        Step 1/8 : FROM hyperledger/fabric-baseos:x86_64-0.3.2
        ---> bbcbb9da2d83
        Step 2/8 : ENV FABRIC_CFG_PATH /etc/hyperledger/fabric
        ---> Running in f340144076b5
        Removing intermediate container f340144076b5
        ---> 0b638a580b61
        Step 3/8 : RUN mkdir -p /var/hyperledger/production $FABRIC_CFG_PATH
        ---> Running in 965b23d0fb0c
        Removing intermediate container 965b23d0fb0c
        ---> e98d73d59ac3
        Step 4/8 : COPY payload/orderer /usr/local/bin
        ---> cfdf61c65821
        Step 5/8 : ADD payload/sampleconfig.tar.bz2 $FABRIC_CFG_PATH/
        ---> 0a4b15c65c40
        Step 6/8 : EXPOSE 7050
        ---> Running in 35490870571a
        Removing intermediate container 35490870571a
        ---> 25122bbcbf1d
        Step 7/8 : CMD ["orderer"]
        ---> Running in 52c6b2bb5c5b
        Removing intermediate container 52c6b2bb5c5b
        ---> 5f1b61eaf6b5
        Step 8/8 : LABEL org.hyperledger.fabric.version=1.0.3       org.hyperledger.fabric.base.version=0.3.2
        ---> Running in c7726d44b815
        Removing intermediate container c7726d44b815
        ---> 04ae17fa19e1
Successfully built 04ae17fa19e1
Successfully tagged hyperledger/fabric-orderer:latest
docker tag hyperledger/fabric-orderer hyperledger/fabric-orderer:x86_64-1.0.3
touch build/image/orderer/.dummy-x86_64-1.0.3
```

- Output
    - `hyperledger/fabric-orderer:latest` image, `hyperledger/fabric-orderer:x86_64-1.0.3` image
        - From `hyperledger/fabric-baseos:x86_64-0.3.2`
                - `FABRIC_CFG_PATH`: `/etc/hyperledger/fabric`
                    - `/etc/hyperledger/fabric` created
                    - `sampleconfig.tar.bz2` decompressed and unpacked `/etc/hyperledger/fabric`
                - `/var/hyperledger/production` created
                - `orderer` (**built using `baseimage`**) in `/usr/local/bin`
                - `CMD ["orderer"]`
### `build/image/%/payload`

```bash
Creating build/image/orderer/payload
mkdir -p build/image/orderer/payload
cp build/docker/bin/orderer build/sampleconfig.tar.bz2 build/image/orderer/payload
```

#### `build/image/orderer/payload`
- Translates to
	
        ```bash
        build/image/orderer/payload:    build/docker/bin/orderer \
				build/sampleconfig.tar.bz2
        ```

##### 1. `build/docker/bin/orderer`
- `build/docker/bin/%: $(PROJECT_FILES)`
	
        ```bash
        Building build/docker/bin/orderer
        mkdir -p build/docker/bin build/docker/orderer/pkg
        docker run -i --rm --user=1000 -v /home/centos/go/src/github.com/hyperledger/fabric:/opt/gopath/src/github.com/hyperledger/fabric -w /opt/gopath/src/github.com/hyperledger/fabric \
                -v /home/centos/go/src/github.com/hyperledger/fabric/build/docker/bin:/opt/gopath/bin \
                -v /home/centos/go/src/github.com/hyperledger/fabric/build/docker/orderer/pkg:/opt/gopath/pkg \
                hyperledger/fabric-baseimage:x86_64-0.3.2 \
                go install -ldflags "-X github.com/hyperledger/fabric/common/metadata.Version=1.0.3 -X github.com/hyperledger/fabric/common/metadata.BaseVersion=0.3.2 -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=hyperledger -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=hyperledger -linkmode external -extldflags '-static -lpthread'" github.com/hyperledger/fabric/orderer
        touch build/docker/bin/orderer
        ```

- Output
    - `orderer` under `build/docker/bin`
##### 2. `build/sampleconfig.tar.bz2: $(shell find sampleconfig -type f)`
- See previous occurrence
## 3. `ccenv` - `build/image/%/$(DUMMY): Makefile build/image/%/payload build/image/%/Dockerfile`
- By product of build `make peer` of `make peer-docker`
## 4. `tools` - `build/image/%/$(DUMMY): Makefile build/image/%/payload build/image/%/Dockerfile`

```bash
Building docker tools-image
docker build  -t hyperledger/fabric-tools build/image/tools
Sending build context to Docker daemon  70.33MB
        Step 1/9 : FROM hyperledger/fabric-baseimage:x86_64-0.3.2
        ---> c92d9fdee998
        Step 2/9 : ENV FABRIC_CFG_PATH /etc/hyperledger/fabric
        ---> Running in bc53d1465afb
        Removing intermediate container bc53d1465afb
        ---> 4d579746e8be
        Step 3/9 : VOLUME /etc/hyperledger/fabric
        ---> Running in feaeb28c1414
        Removing intermediate container feaeb28c1414
        ---> c7e38282a8b8
        Step 4/9 : ADD  payload/sampleconfig.tar.bz2 $FABRIC_CFG_PATH
        ---> ec222c5ca3fe
        Step 5/9 : COPY payload/cryptogen /usr/local/bin
        ---> 774b1c3b9878
        Step 6/9 : COPY payload/configtxgen /usr/local/bin
        ---> a45e9abe3ee3
        Step 7/9 : COPY payload/configtxlator /usr/local/bin
        ---> c4311ecc4923
        Step 8/9 : COPY payload/peer /usr/local/bin
        ---> 4b46dacffbe8
        Step 9/9 : LABEL org.hyperledger.fabric.version=1.0.3       org.hyperledger.fabric.base.version=0.3.2
        ---> Running in 0bf9529c3705
        Removing intermediate container 0bf9529c3705
        ---> cff0436b6747
Successfully built cff0436b6747
Successfully tagged hyperledger/fabric-tools:latest
docker tag hyperledger/fabric-tools hyperledger/fabric-tools:x86_64-1.0.3
touch build/image/tools/.dummy-x86_64-1.0.3
```

- Output
    - `hyperledger/fabric-tools:latest` image, `hyperledger/fabric-tools:x86_64-1.0.3`
                - `FABRIC_CFG_PATH`: `/etc/hyperledger/fabric`
                    - `/etc/hyperledger/fabric` created
                    - `sampleconfig.tar.bz2` decompressed and unpacked `/etc/hyperledger/fabric`
                    - **`VOLUME /etc/hyperledger/fabric`**
                        - > https://docs.docker.com/storage/volumes/
                        - > https://www.cnblogs.com/51kata/p/5266626.html
                        - > https://yeasy.gitbooks.io/docker_practice/image/dockerfile/volume.html
                - `/var/hyperledger/production` created
                - `cryptogen`, `configtxgen`, `configtxlator`, `peer` in `/usr/local/bin`
- > `docker inspect cli | less`
	
        ```js
        "Mounts": [
            // ...
            {
                "Type": "volume",
                "Name": "4e5c61b23b176078641fb8ac3a495c8cd6ca7e23620292709ce1b2be3c26678b",
                "Source": "/var/lib/docker/volumes/4e5c61b23b176078641fb8ac3a495c8cd6ca7e23620292709ce1b2be3c26678b/_data",
                "Destination": "/etc/hyperledger/fabric", // here
                "Driver": "local",
                "Mode": "",
                "RW": true,
                "Propagation": ""
            },
            // ...
        ]
        ```

### `build/image/%/payload`

```bash
Creating build/image/tools/payload
mkdir -p build/image/tools/payload
cp build/docker/bin/cryptogen build/docker/bin/configtxgen build/docker/bin/configtxlator build/docker/bin/peer build/sampleconfig.tar.bz2 build/image/tools/payload
```

#### `build/image/tools/payload`
- Translates to
	
        ```bash
        build/image/tools/payload:      build/docker/bin/cryptogen \
	                        build/docker/bin/configtxgen \
	                        build/docker/bin/configtxlator \
				build/docker/bin/peer \
				build/sampleconfig.tar.bz2
        ```

##### 1. `build/docker/bin/cryptogen`
- `build/docker/bin/%: $(PROJECT_FILES)`

        ```bash
        Building build/docker/bin/cryptogen
        mkdir -p build/docker/bin build/docker/cryptogen/pkg
        docker run -i --rm --user=1000 -v /home/centos/go/src/github.com/hyperledger/fabric:/opt/gopath/src/github.com/hyperledger/fabric -w /opt/gopath/src/git
        hub.com/hyperledger/fabric \
                -v /home/centos/go/src/github.com/hyperledger/fabric/build/docker/bin:/opt/gopath/bin \
                -v /home/centos/go/src/github.com/hyperledger/fabric/build/docker/cryptogen/pkg:/opt/gopath/pkg \
                hyperledger/fabric-baseimage:x86_64-0.3.2 \
                go install -ldflags "-X github.com/hyperledger/fabric/common/metadata.Version=1.0.3 -X github.com/hyperledger/fabric/common/metadata.BaseVersion
        =0.3.2 -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric -X github.com/hyperledger/fabric/common/metadata.DockerNa
        mespace=hyperledger -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=hyperledger -linkmode external -extldflags '-static -lpthread'"
        github.com/hyperledger/fabric/common/tools/cryptogen
        touch build/docker/bin/cryptogen
        ```

##### 2. `build/docker/bin/configtxgen`
- `build/docker/bin/%: $(PROJECT_FILES)`
	
        ```bash
        mkdir -p build/docker/bin build/docker/configtxgen/pkg
        docker run -i --rm --user=1000 -v /home/centos/go/src/github.com/hyperledger/fabric:/opt/gopath/src/github.com/hyperledger/fabric -w /opt/gopath/src/git
        hub.com/hyperledger/fabric \
                -v /home/centos/go/src/github.com/hyperledger/fabric/build/docker/bin:/opt/gopath/bin \
                -v /home/centos/go/src/github.com/hyperledger/fabric/build/docker/configtxgen/pkg:/opt/gopath/pkg \
                hyperledger/fabric-baseimage:x86_64-0.3.2 \
                go install -ldflags "-X github.com/hyperledger/fabric/common/metadata.Version=1.0.3 -X github.com/hyperledger/fabric/common/metadata.BaseVersion=0.3.2 -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=hyperledger -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=hyperledger -linkmode external -extldflags '-static -lpthread'" github.com/hyperledger/fabric/common/configtx/tool/configtxgen
        touch build/docker/bin/configtxgen
        ```

##### 3. `build/docker/bin/configtxlator`
- `build/docker/bin/%: $(PROJECT_FILES)`
	
        ```bash
        Building build/docker/bin/configtxlator
        mkdir -p build/docker/bin build/docker/configtxlator/pkg
        docker run -i --rm --user=1000 -v /home/centos/go/src/github.com/hyperledger/fabric:/opt/gopath/src/github.com/hyperledger/fabric -w /opt/gopath/src/github.com/hyperledger/fabric \
                -v /home/centos/go/src/github.com/hyperledger/fabric/build/docker/bin:/opt/gopath/bin \
                -v /home/centos/go/src/github.com/hyperledger/fabric/build/docker/configtxlator/pkg:/opt/gopath/pkg \
                hyperledger/fabric-baseimage:x86_64-0.3.2 \
                go install -ldflags "-X github.com/hyperledger/fabric/common/metadata.Version=1.0.3 -X github.com/hyperledger/fabric/common/metadata.BaseVersion=0.3.2 -X github.com/hyperledger/fabric/common/metadata.BaseDockerLabel=org.hyperledger.fabric -X github.com/hyperledger/fabric/common/metadata.DockerNamespace=hyperledger -X github.com/hyperledger/fabric/common/metadata.BaseDockerNamespace=hyperledger -linkmode external -extldflags '-static -lpthread'" github.com/hyperledger/fabric/common/tools/configtxlator
        touch build/docker/bin/configtxlator
        ```

##### 4. `build/docker/bin/peer`
- See previous occurrence
##### 5. `build/sampleconfig.tar.bz2`
- See previous occurrence
## 5. `kafka` - `build/image/%/$(DUMMY): Makefile build/image/%/payload build/image/%/Dockerfile`

## 6. `zookeeper` - `build/image/%/$(DUMMY): Makefile build/image/%/payload build/image/%/Dockerfile`

# `make release`
