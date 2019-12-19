<!-- https://blog.csdn.net/idsuf698987/article/details/74912362 -->

- `peer` 目录下有一个 `main.go` 文件，其余文件夹除 `common`, `gossip` 外均为子命令集合，有 `chaincode`, `channel`, `cliloggin`, `node`, `version` 共 5 个供 `main.go` 整合使用。
- 子命令文件夹中，与文件夹名称相同的 `.go` 文件为主要源码文件，其余的均为按功能划分的**动作**命令源码。
- [cobra](https://github.com/spf13/cobra)
	
    ```go
    RootCmd := &cobra.Command{
        /* ... */ 
        // The one-line usage message. 定义的命令名称，如 `peer`
        Use string
        Short string
        // The long message shown in the 'help <this-command>' output.
        Long string
        // Run: Typically the actual work function. Most commands will only implement this.
        Run func(cmd *Command, args []string)
        // RunE: Run but returns an error.
	    RunE func(cmd *Command, args []string) error
        /* ... */         
    }
    // flag
    RootCmd.PersistentFlags().BoolVarP(&Verbose, "verbose", "v", false, "verbose output")
    RootCmd.Flags().StringVarP(&Source, "source", "s", "", "Source directory to read from")
    // 子命令，子命令与根命令本质相同，只是人为地进行级别上的区分
    RootCmd.AddCommand(versionCmd)
    // 运行命令
    RootCmd.Execute()
    ```

- `peer` 命令结构
    - `PersistentPreRunE` 先于 `Run` 执行；`mainCmd` 只单纯作为根命令，不实现由子命令实现的具体的交易事务，因此实现的只是 `PersistentPreRunE` 指定的检查、初始化日志系统并缓存配置的功能，和 `Run` 指定的版本打印、命令帮助功能。
    - 生成 `mainCmd` 对象的命令行标识对象 `mainFlags`，`mainFlags := mainCmd.PersistentFlags()`，也就是 `peer` 命令的选项，增加了 `version`, `logging_level` 两个选项，对应了其在自身对象中设置 `PersistentPreRunE` 和 `Run` 的功能。
    - 添加子命令，`mainCmd.AddCommand()`。添加的命令有 `version.Cmd()`, `node.Cmd()`, `chaincode.Cmd(nil)`, `clilogging.Cmd(nil)`, `channel.Cmd(nil)` 五个。
        - `Cmd()` 是每个子命令文件中暴露出的函数，各自整合了各自的动作命令。
    - 启动根命令，`mainCmd.Execute()`。启动了根命令，也就启动了其下的所有命令。
- 在每个 peer 容器启动后默认执行的就是 `peer node start –peer-defaultchain=false` 命令，该命令最终调用执行的就是 `serve` 函数。
    - `serve` 重要