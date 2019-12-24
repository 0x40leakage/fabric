<!-- https://blog.csdn.net/idsuf698987/article/details/75223986 -->

- Fabric 的日志系统主要使用了第三方包 [go-logging](https://github.com/op/go-logging)，在此基础上封装出 `fabric/common/flogging`；很少一部分使用了 Go 语言标准库中的 `log`。
- 基本用法

    ```go
    // 创建一个名为 example 的日志对象
    var log = logging.MustGetLogger("example")
    // 创建一个日志输出格式对象
    var format = logging.MustStringFormatter(
        `%{color}%{time:15:04:05.000} %{shortfunc} ▶ %{level:.4s} %{id:03x}%{color:reset} %{message}`,
    )
    // 创建一个日志输出对象的 backend，也就是日志要打印到哪，此处是标准错误输出
    backend := logging.NewLogBackend(os.Stderr, "", 0)
    // 将输出格式与输出对象绑定
    backendFormatter := logging.NewBackendFormatter(backend, format)
    // 将绑定了格式的输出对象设置为日志的输出对象，这样打印每一句话都会按格式输出到 backendFormatter 所代表的对象里，在此即是标准错误输出
    logging.SetBackend(backendFormatter)
    log.Info("info")
    log.Error("err")
    ```

- `grpclogger` implements the standard Go logging interface and wraps the `logger` provided by the `flogging` package.  This is required in order to replace the default `log` used by the `grpclog` package.