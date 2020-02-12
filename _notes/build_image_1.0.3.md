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
    - 6: `protoc-gen-go`, `govendor` under `./build/docker/gotools/bin` (`-v` specified)
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

- [ ] Q

        ```bash
        docker run -it --user=1000 -v /home/centos/go/src/github.com/hyperledger/fabric:/opt/gopath/src/github.com/hyperledger/fabric -w /opt/gopath/src/github.com/hyperledger/fabric \
        -v /home/centos/go/src/github.com/hyperledger/fabric/build/docker/gotools:/opt/gotools \
        -w /opt/gopath/src/github.com/hyperledger/fabric/gotools \
        hyperledger/fabric-baseimage:x86_64-0.3.2 \
         bash

        # run inside baseimage container

        # make install BINDIR=/opt/gotools/bin OBJDIR=/opt/gotools/obj
        # make install OBJDIR=/opt/gotools/obj
        # make install BINDIR=/opt/gotools/bin
        # make install
        ```

## 2. `orderer: build/bin/orderer`
- Output
    - `orderer` under `./build/bin` (`GOBIN` specified)
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
    - `configtxgen`, `cryptogen`, `configtxlator` under `./build/bin` (`GOBIN` specified)
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
## 1. `docker: build/image/peer/$(DUMMY)`
- Recipe

    ```bash
    # 1.
      # 1.1 special prerequisites
      build/image/peer/$(DUMMY): build/image/ccenv/$(DUMMY)

        # 2.1. general recipe for both prerequisites and commands)
        #    see make native - peer - output 3
        build/image/%/$(DUMMY): Makefile build/image/%/payload build/image/%/Dockerfile

      # 1.2 general recipe for both prerequisites and commands 
      build/image/%/$(DUMMY): Makefile build/image/%/payload build/image/%/Dockerfile
        $(eval TARGET = ${patsubst build/image/%/$(DUMMY),%,${@}})
        @echo "Building docker $(TARGET)-image"
        $(DBUILD) -t $(DOCKER_NS)/fabric-$(TARGET) $(@D)
        docker tag $(DOCKER_NS)/fabric-$(TARGET) $(DOCKER_NS)/fabric-$(TARGET):$(DOCKER_TAG)
        touch $@

        # 2.2
          # 2.2.1
            # 2.2.1.1
            build/image/peer/payload:       build/docker/bin/peer \
				build/sampleconfig.tar.bz2
            # 2.2.1.2
            build/image/%/payload:
              @echo "Creating $@"
              mkdir -p $@
              cp $^ $@
          # 2.2.2
          build/image/%/Dockerfile: images/%/Dockerfile.in
            @echo "creating Dockerfile"
            @cat $< \
                | sed -e 's/_BASE_NS_/$(BASE_DOCKER_NS)/g' \
                | sed -e 's/_NS_/$(DOCKER_NS)/g' \
                | sed -e 's/_BASE_TAG_/$(BASE_DOCKER_TAG)/g' \
                | sed -e 's/_TAG_/$(DOCKER_TAG)/g' \
                > $@
            @echo LABEL $(BASE_DOCKER_LABEL).version=$(PROJECT_VERSION) \\>>$@
            @echo "     " $(BASE_DOCKER_LABEL).base.version=$(BASEIMAGE_RELEASE)>>$@
          # 2.2.3 
          Makefile
    ```

- `/var/hyperledger/production` created
## 2. `docker: build/image/orderer/$(DUMMY)`
- `/var/hyperledger/production` created
## 3. `docker: build/image/ccenv/$(DUMMY)`
## 4. `docker: build/image/tools/$(DUMMY)`
- **`VOLUME /etc/hyperledger/fabric`**
    - > https://docs.docker.com/storage/volumes/
    - > https://www.cnblogs.com/51kata/p/5266626.html
    - > https://yeasy.gitbooks.io/docker_practice/image/dockerfile/volume.html
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

## 5. `docker: build/image/kafka/$(DUMMY)`

- Recipe

    ```bash
    build/image/%/$(DUMMY): Makefile build/image/%/payload build/image/%/Dockerfile
	  $(eval TARGET = ${patsubst build/image/%/$(DUMMY),%,${@}})
	  @echo "Building docker $(TARGET)-image"
	  $(DBUILD) -t $(DOCKER_NS)/fabric-$(TARGET) $(@D)
	  docker tag $(DOCKER_NS)/fabric-$(TARGET) $(DOCKER_NS)/  fabric-$(TARGET):$(DOCKER_TAG)
	  touch $@

      build/image/%/payload
        @echo "Creating $@"
          mkdir -p $@
          cp $^ $@
      build/image/kafka/payload:      images/kafka/docker-entrypoint.sh \
				images/kafka/kafka-run-class.sh

      build/image/%/Dockerfile: images/%/Dockerfile.in
        @echo "creating Dockerfile"
        @cat $< \
            | sed -e 's/_BASE_NS_/$(BASE_DOCKER_NS)/g' \
            | sed -e 's/_NS_/$(DOCKER_NS)/g' \
            | sed -e 's/_BASE_TAG_/$(BASE_DOCKER_TAG)/g' \
            | sed -e 's/_TAG_/$(DOCKER_TAG)/g' \
            > $@
        @echo LABEL $(BASE_DOCKER_LABEL).version=$(PROJECT_VERSION) \\>>$@
        @echo "     " $(BASE_DOCKER_LABEL).base.version=$(BASEIMAGE_RELEASE)>>$@
    ```

## 6. `docker: build/image/zookeeper/$(DUMMY)`

# `make release`
- Recipe

    ```bash
    # MARCH=$(shell go env GOOS)-$(shell go env GOARCH)
    release: $(patsubst %,release/%, $(MARCH))

      release/%: GO_LDFLAGS=-X $(pkgmap.$(@F))/metadata.Version=$  (PROJECT_VERSION)

      release/%-amd64: DOCKER_ARCH=x86_64
      release/%-amd64: GOARCH=amd64
      release/linux-%: GOOS=linux
  
      # linux-amd64
      release/linux-amd64: GOOS=linux
      release/linux-amd64: GO_TAGS+= nopkcs11
      # RELEASE_PKGS = configtxgen cryptogen configtxlator peer orderer
      release/linux-amd64: $(patsubst %,release/linux-amd64/bin/%, $  (RELEASE_PKGS)) release/linux-amd64/install
        
        release/%/bin/configtxgen: $(PROJECT_FILES)
            @echo "Building $@ for $(GOOS)-$(GOARCH)"
            mkdir -p $(@D)
            $(CGO_FLAGS) GOOS=$(GOOS) GOARCH=$(GOARCH) go build -o $(abspath $@) -tags "$(GO_TAGS)" -ldflags "$(GO_LDFLAGS)" $(pkgmap.$(@F))

        # etc..

        release/%/install: $(PROJECT_FILES)
            mkdir -p $(@D)/bin
            # pull docker images

              # ifneq ($(IS_RELEASE),true)
              # EXTRA_VERSION ?= snapshot-$(shell git rev-parse --short HEAD)
              # PROJECT_VERSION=$(BASE_VERSION)-$(EXTRA_VERSION)
              # else
              # PROJECT_VERSION=$(BASE_VERSION)
              # endif
              # BASE_VERSION = 1.0.3
              # EXTRA_VERSION ?= snapshot-298322489


            @cat $(@D)/../templates/get-docker-images.in \
                | sed -e 's/_NS_/$(DOCKER_NS)/g' \
                | sed -e 's/_ARCH_/$(DOCKER_ARCH)/g' \
                | sed -e 's/_VERSION_/$(PROJECT_VERSION)/g' \
                | sed -e 's/_BASE_DOCKER_TAG_/$(BASE_DOCKER_TAG)/g' \
                > $(@D)/bin/get-docker-images.sh
                @chmod +x $(@D)/bin/get-docker-images.sh

            # downloads the build your first network sample app 
            @cat $(@D)/../templates/get-byfn.in \
                | sed -e 's/_VERSION_/$(PROJECT_VERSION)/g' \
                > $(@D)/bin/get-byfn.sh
                @chmod +x $(@D)/bin/get-byfn.sh
    ```
