- [Text functions](https://www.gnu.org/software/make/manual/html_node/Text-Functions.html)
    - `$(patsubst pattern,replacement,text)`
        - Finds whitespace-separated words in `text` that match `pattern` and replaces them with `replacement`.
        - `pattern` may contain a ‘%’ which acts as a wildcard, matching any number of any characters within a word. If `replacement` also contains a ‘%’, the ‘%’ is replaced by the text that matched the ‘%’ in `pattern`.
            - Only the first ‘%’ in the `pattern` and `replacement` is treated this way; any subsequent ‘%’ is unchanged.
    - `$(subst from,to,text)`
        - Performs a textual replacement on the text `text`: each occurrence of `from` is replaced by `to`. The result is substituted for the function call.
- [File name functions](https://www.gnu.org/software/make/manual/html_node/File-Name-Functions.html)
    - `abspath`
        - For each file name in names return an absolute name that does not contain any `.` or `..` components, nor any repeated path separators (`/`). Note that, in contrast to `realpath` function, `abspath` does not resolve symlinks and does not require the file names to refer to an existing file or directory. Use the wildcard function to test for existence.
- *[Automatic Variables](https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html)*
    - `$@`
        - The file name of the target of the rule
        - If the target is an archive member, then `$@` is the name of the archive file
        - In a pattern rule that has multiple targets (see Introduction to Pattern Rules), `$@` is the name of whichever target caused the rule’s recipe to be run.
    - `$^` 
        - The names of **all the prerequisites**, with spaces between them
            - A target has only one prerequisite on each other file it depends on, no matter how many times each file is listed as a prerequisite. So if you list a prerequisite more than once for a target, the value of `$^` contains just one copy of the name
        - For prerequisites which are archive members, only the named member is used (see Archives)
        - This list does not contain any of the order-only prerequisites; for those see the `$|` variable
    - `$<`
        - The name of the **first prerequisite**
        - If the target got its recipe from an implicit rule, this will be the first prerequisite added by the implicit rule (see Implicit Rules).
    - `$(@F)`
        - The file-within-directory part of the file name of the target
            - If the value of `$@` is `dir/foo.o` then `$(@F)` is `foo.o`
        - `$(@F)` is equivalent to `$(notdir $@)`
    - `$(@D)`
        - The **directory part** of the file name of the target, with the **trailing slash removed**
            - If the value of `$@` is `dir/foo.o` then `$(@D)` is `dir`
        - This value is `.` if `$@` does not contain a slash
- **不同 target，prerequisites 不同，但是 commands 可以套同一个模板，所以对某一个 target， prerequisites 单独写，commands 套用模板**
    - 没有命令的 `make` 规则下面不要加 `@echo` 来打印日志，会覆盖通用的命令模板！
- `make native` 和 `make docker` 都会编二进制，因 host 环境和 docker 容器的环境大概率不同，此处不加判断无差别
- **target 通常是文件名，或是伪目标 (`.PHONY`)**
- [ ] Why isn't `native`, `docker`, `all`, etc., declared as `.PHONY`?

- [ ] `sed`
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
## 1. `peer: build/bin/peer`
- Output
    - 6: `protoc-gen-go`, `govendor` under `./build/docker/gotools/bin`
        - `./build/docker/gotools/obj/gopath` holds the temporary `GOPATH` for inside the container
        - Volume
            - `./fabric/build/docker/gotools:/opt/gotools`
            - `./fabric:/opt/gopath/src/github.com/hyperledger`
    - 5
        - 5.1: see 6
        - 5.2: `chaintool` under `./build/bin`
        - 5.3: `goshim.tar.bz2` under `./build`
    - 4
        - 4.1: `build/image/ccenv/payload` directory created; `protoc-gen-go` (no `govendor` and such), `chaintool`, `goshim.tar.bz2` under `./build/image/ccenv/payload`
        - 4.2: `Dockerfile` under `./build/image/ccenv`
    - 3: `.dummy-x86_64-1.0.3` under `./build/image/ccenv`; `hyperledger/fabric-ccenv:latest` image, `hyperledger/fabric-ccenv:x86_64-1.0.3` image
        - Container-wise: `chaintool`, `protoc-gen-go` under `/usr/local/bin/`; `goshim.tar.bz2` decompressed and unpacked into `$GOPATH/src/`
    - 2: `peer` under `./build/bin`
- Recipe
	
        ```makefile
        # 1. .PHONY: peer
        peer: build/bin/peer
          ## 2.1 special prerequisites of its own
          build/bin/peer: build/image/ccenv/$(DUMMY)
            ### 3. general recipe (both prerequisites and commands)
            build/image/%/$(DUMMY): Makefile build/image/%/payload build/image/%/Dockerfile
              $(eval TARGET = ${patsubst build/image/%/$(DUMMY),%,${@}})
              @echo "Building docker $(TARGET)-image"
              $(DBUILD) -t $(DOCKER_NS)/fabric-$(TARGET) $(@D)
              docker tag $(DOCKER_NS)/fabric-$(TARGET) $(DOCKER_NS)/fabric-$(TARGET):$(DOCKER_TAG)
              touch $@

              #### 4.1 separated prerequisites and commands
                ##### 4.1.1 required prerequisites 
                build/image/ccenv/payload:      build/docker/gotools/bin/protoc-gen-go \
				                build/bin/chaintool \
				                build/goshim.tar.bz2
                  ###### 5.1 purpose to to make protoc-gen-go (with other tools also specified in GOTOOLS as by product)
                  build/docker/gotools/bin/protoc-gen-go: build/docker/gotools
                    ####### 6. analyse later
                    build/docker/gotools: gotools/Makefile
                      mkdir -p $@/bin $@/obj
                      $(DRUN) \
                          -v $(abspath $@):/opt/gotools \
                          -w /opt/gopath/src/$(PKGNAME)/gotools \
                          $(BASE_DOCKER_NS)/fabric-baseimage:$(BASE_DOCKER_TAG) \
                          make install BINDIR=/opt/gotools/bin OBJDIR=/opt/gotools/obj

                  ###### 5.2
                  %/chaintool: Makefile
                    @echo "Installing chaintool"
                    mkdir -p $(@D)
                    cp ./cached/hyperledger-fabric-chaintool-1.0.0.jar $@
                    chmod +x $@
                  ###### 5.3
                  build/goshim.tar.bz2: $(GOSHIM_DEPS)
                    @echo "Creating $@"
                    @tar -jhc -C $(GOPATH)/src $(patsubst $(GOPATH)/src/%,%,$(GOSHIM_DEPS)) > $@

                ##### 4.1.2 command
                build/image/%/payload:
                  @echo "Creating $@"
                  mkdir -p $@
                  cp $^ $@    

              #### 4.2 purpose is to create the target (a file); prerequisites exist, go straight to execute the command
              build/image/%/Dockerfile: images/%/Dockerfile.in
                @cat $< \
                        | sed -e 's/_BASE_NS_/$(BASE_DOCKER_NS)/g' \
                        | sed -e 's/_NS_/$(DOCKER_NS)/g' \
                        | sed -e 's/_BASE_TAG_/$(BASE_DOCKER_TAG)/g' \
                        | sed -e 's/_TAG_/$(DOCKER_TAG)/g' \
                        > $@
                @echo LABEL $(BASE_DOCKER_LABEL).version=$(PROJECT_VERSION) \\>>$@
                @echo "     " $(BASE_DOCKER_LABEL).base.version=$(BASEIMAGE_RELEASE)>>$@ 
              #### 4.3 exists (common file)
              Makefile

          ## 2.2 general recipe of command
          build/bin/%: $(PROJECT_FILES)
            @echo
	    mkdir -p $(@D)
	    @echo "$@"
	    $(CGO_FLAGS) GOBIN=$(abspath $(@D)) go install -tags "$(GO_TAGS)" -ldflags "$(GO_LDFLAGS)" $(pkgmap.$(@F))
	    @echo "Binary available as $@"
	    @touch $@
        ```

- `make install BINDIR=/opt/gotools/bin OBJDIR=/opt/gotools/obj`
	
        ```makefile
        docker run -i --rm --user=1000 
                # flags from from $(DRUN)
                -v /home/centos/go/src/github.com/hyperledger/fabric:/opt/gopath/src/github.com/hyperledger/fabric \
                -w /opt/gopath/src/github.com/hyperledger/fabric \

                -v /home/centos/go/src/github.com/hyperledger/fabric/build/docker/gotools:/opt/gotools \
                # gotool/Makefile at work; override work directory
                -w /opt/gopath/src/github.com/hyperledger/fabric/gotools \
                # pull if not exists. https://github.com/hyperledger/fabric-baseimage
                hyperledger/fabric-baseimage:x86_64-0.3.2 \
                # **inside baseimage container** (override default flags: BINDIR ?= /usr/local/bin; OBJDIR ?= build)
                make install BINDIR=/opt/gotools/bin OBJDIR=/opt/gotools/obj
                # BINDIR=/opt/gotools/bin: 解决 cp 权限问题


        # 1. GOTOOLS_BIN: /opt/gotools/obj/gopath/bin/protoc-gen-go /opt/gotools/obj/gopath/bin/govendor
        install: $(GOTOOLS_BIN)
	  mkdir -p $(BINDIR)
	  cp $^ $(BINDIR) # BINDER: /opt/gotools/bin (explicitly passed in, NOT from BINDIR ?= /usr/local/bin)

          ## 2. GOBIN: /opt/gotools/obj/gopath/bin
          $(GOBIN)/%:
	    @echo "GOBIN: $(GOBIN), GOTOOLS_BIN: $(GOTOOLS_BIN)"
	    $(eval TOOL = ${subst $(GOBIN)/,,${@}})
	    $(MAKE) gotool.$(TOOL)

            ### 3.1 Special override for protoc-gen-go since we want to use the version vendored with the project
            gotool.protoc-gen-go:
              @echo "Building github.com/golang/protobuf/protoc-gen-go -> protoc-gen-go"
              mkdir -p $(TMP_GOPATH)/src/github.com/golang/protobuf/
              cp -R $(GOPATH)/src/github.com/hyperledger/fabric/vendor/github.com/golang/protobuf/* $(TMP_GOPATH)/src/github.com/golang/protobuf
              GOPATH=$(abspath $(TMP_GOPATH)) go install github.com/golang/protobuf/protoc-gen-go
              @echo

            ### 3.2 Default rule for gotools uses the name->path map for a generic 'go get' style build
            gotool.%:
              $(eval TOOL = ${subst gotool.,,${@}})
              @echo "Building ${go.fqp.${TOOL}} -> $(TOOL)"
              GOPATH=$(abspath $(TMP_GOPATH)) go get ${go.fqp.${TOOL}}
              @echo
        ```

- Q

        ```bash
        # OBJDIR=/opt/gotools/obj: 

        # run inside baseimage container
        make install BINDIR=/opt/gotools/bin OBJDIR=/opt/gotools/obj # with OBJDIR
        # make gotool.protoc-gen-go
        # make[1]: Entering directory '/opt/gopath/src/github.com/hyperledger/fabric/gotools'
        # Building github.com/golang/protobuf/protoc-gen-go -> protoc-gen-go
        # make[1]: Leaving directory '/opt/gopath/src/github.com/hyperledger/fabric/gotools'
        # mkdir -p /opt/gotools/bin
        # cp /opt/gotools/obj/gopath/bin/protoc-gen-go /opt/gotools/bin

        make install OBJDIR=/opt/gotools/obj # with OBJDIR
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

## 2. `orderer: build/bin/orderer`
- Output
    - `orderer` under `./build/bin`
- Recipe
	
        ```bash
        # 1. .PHONY: orderer
        orderer: build/bin/orderer
          # 2.
          build/bin/%: $(PROJECT_FILES)
	    @echo
	    mkdir -p $(@D)
	    @echo "$@"
	    $(CGO_FLAGS) GOBIN=$(abspath $(@D)) go install -tags "$(GO_TAGS)"     -ldflags "$(GO_LDFLAGS)" $(pkgmap.$(@F))
	    @echo "Binary available as $@"
	    @touch $@
        ```

## `configtxgen: build/bin/configtxgen`, `cryptogen: build/bin/cryptogen`, `configtxlator: build/bin/configtxlator`
- Output
    - `configtxgen`, `cryptogen`, `configtxlator` under `./build/bin` (`GOBIN`)
- Recipe

    ```bash
    # 1. .PHONY: configtxgen
    configtxgen: GO_TAGS+= nopkcs11
    configtxgen: GO_LDFLAGS=-X $(pkgmap.$(@F))/metadata.Version=$(PROJECT_VERSION)
    configtxgen: build/bin/configtxgen
      # 2. build/bin/%: $(PROJECT_FILES)
        @echo
        mkdir -p $(@D)
        $(CGO_FLAGS) GOBIN=$(abspath $(@D)) go install -tags "$(GO_TAGS)" -ldflags "$(GO_LDFLAGS)" $(pkgmap.$(@F))
        @echo "Binary available as $@"
        @touch $@
    ```

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
