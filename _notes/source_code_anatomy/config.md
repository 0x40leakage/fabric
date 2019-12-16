<!-- https://blog.csdn.net/idsuf698987/article/details/75224228 -->

# 配置
- Fabric 索取配置的途径有：环境变量，命令行参数，各种格式的配置文件。其中以配置文件为主，环境变量和命令行参数辅助，三者可以相互作用。
- 主要的配置文件有 `core.yaml`, `orderer.yaml` 等，在 `/fabric/sampleconfig` 中有示例。
- 主要配置相关的代码集中在 `/fabric/core/config` 下。
## 配置文件
- > [viper](https://github.com/spf13/viper)

    ```go
    // 设置一个要读取的配置文件名（不包含后缀），一个 viper 只支持一个文件名
    viper.SetConfigName("config")
    // 设置一个搜索配置文件的路径，viper 的搜索路径可以有多个
    viper.AddConfigPath("/etc/appname/")
    viper.AddConfigPath(".")
    // 读取配置文件
    viper.ReadInConfig()
    // 获取其中一个 name 项的值
    viper.Get("name")
    // 将 name 的值设置为 Bill
    viper.Set("name", "Bill")
    ```

- peer 对 `core.yaml` 的引入
	
    ```go
    /* fabric/peer/main.go */
    const cmdRoot = "core"
    err := common.InitConfig(cmdRoot)

    /* fabric/peer/common/common.go */
    config.InitViper(nil, cmdRoot)
        // fabric/core/config/config.go
        // add (may be several) config path
        addConfigPath()
        // set the configuration file.
        SetConfigName(configName)

    // Viper will discover and load the configuration file from disk
    // and key/value stores, searching in one of the defined paths.
	err := viper.ReadInConfig()
    ```

- orderer 对 `orderer.yaml` 的引入
	
    ```go
    /* fabric/orderer/main.go */
    config.Load()
        /* fabric/orderer/localconfig/config.go */
        Prefix = "ORDERER"
        configName = strings.ToLower(Prefix) // orderer
        cf.InitViper(config, configName)
            // fabric/core/config/config.go
            // 同 peer 处
        err := config.ReadInConfig()
    ```

- 经过 `initViper` 搜索路径为 `FABRIC_CFG_PATH` 或 `./` + `$GOPATH/src/github.com/hyperledger/fabric/sampleconfig` + `/etc/hyperledger/fabric`，搜索的配置文件名为：

    ```go
    func InitViper(v *viper.Viper, configName string) error {
        var altPath = os.Getenv("FABRIC_CFG_PATH") // "/etc/hyperledger/fabric", set in Dockerfile of peer & orderer & cli
        if altPath != "" {
            // If the user has overridden the path with an envvar, its the only path we will consider.
            addConfigPath(v, altPath)
        } else {
            // If we get here, we should use the default paths in priority order:
                // *) CWD
                // *) The $GOPATH based development tree
                // *) /etc/hyperledger/fabric

            // CWD
            addConfigPath(v, "./")
            // DevConfigPath: $GOPATH/src/github.com/hyperledger/fabric/sampleconfig
            err := AddDevConfigPath(v)
            if err != nil {
                return err
            }
            // And finally, the official path: "/etc/hyperledger/fabric"
            if dirExists(OfficialPath) {
                addConfigPath(v, OfficialPath)
            }
        }

        // Now set the configuration file.
        if v != nil {
            v.SetConfigName(configName)
        } else {
            viper.SetConfigName(configName)
        }
        return nil
    }
    ```

- 搜索的配置文件名：
    - `core`: 核心配置，供各个模块使用；在 peer 模块里指定。
    - `orderer`：orderer 配置，orderer 使用；在 orderer 模块里指定。
- 分为全局的 `viper` 和特定的 `viper`（参数 `v`）。由 `viper.AddConfigPath` 或 `viper.SetConfigName` 完成的，则是全局的，由 `v.AddConfigPath` 或 `v.SetConfigName` 完成的，则是特定的。这样可以方便地初始化需要**单独使用** `viper` 模块。
    - 如 `orderer` 在 `fabric/orderer/localconfig/config.go` 的 `Load` 函数中，`config := viper.New()`，然后传给 `InitViper`，`cf.InitViper(config, configName)`。
<!-- continues here -->
- `fabric/peer/node/start.go` 的 `serve` 函数中 `secureConfig, err := peer.GetSecureConfig()` 用来获取安全配置。安全配置结构为 `fabric/core/comm/server.go` 中定义的 `SecureServerConfig`，用于一个 `grpc` 服务端实例。`.key`, `.crt`, `.ca` 文件所在的目录都是在 `core.yaml` 中定义都的 `tls` 文件夹中。
    - `serverKey, err := ioutil.ReadFile(config.GetPath("peer.tls.key.file"))`
## 命令行参数
- `fabric/peer/node/start.go` 的 `startCmd()`函数中，`flags.BoolVarP(&chaincodeDevMode, "peer-chaincodedev", "", false, "Whether peer in chaincode development mode")` 设置了 `peer start` 命令的选项之一 `peer-chaincodedev`，用于赋值文件中的全局变量 `chaincodeDevMode`
- `chaincode` 的模式在 `core.yaml` 中也有定义，`chaincode.mode` 的值为 `net`，为默认选项。而当执行 `peer start` 命令时指定了选项 `peer-chaincodedev=true`，在 `serve()` 函数中，就会使用 `viper.Set("chaincode.mode", chaincode.DevModeUserRunsChaincode)` 将 `chaincode` 的模式值设置成 `dev`
## 环境变量
- Fabric 目前的阶段，各个 peer 都是在容器中运行，因此环境变量指的是各个**容器中的环境变量**
- `fabric/peer/main.go`
	
    ```go
    // For environment variables.
	viper.SetEnvPrefix(cmdRoot) // "core"
    viper.AutomaticEnv()
    // 将环境变量中的 `_` 换成 `.` ，和 yaml 文件的配置相匹配
    // viper 读取 yaml 文件所形成的配置项就是按层级并以 `.` 分隔的格式，如 peer.address
	replacer := strings.NewReplacer(".", "_")
	viper.SetEnvKeyReplacer(replacer)
    ```
