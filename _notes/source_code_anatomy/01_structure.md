<!-- https://blog.csdn.net/idsuf698987/article/details/74912362 -->

```bash
# $GOPATH/github.com/hyperledger/fabric
grep "func main" * -r -n --include=*.go > func_main.txt
# 根据 test, example, vendor, build/docker 剔除后
# common/tools/cryptogen/main.go:206:func main() {
# common/tools/configtxlator/main.go:43:func main() {
# common/configtx/tool/configtxgen/main.go:335:func main() {
# orderer/main.go:61:func main() {
# peer/main.go:75:func main() {
```

- 惯例
    - `common` 目录是其所在的层级中的公用代码。
        - `A/common` 说明该 `common` 中的代码在 `A` 范围中公用，`A/B/C/common` 说明该  `common` 中的代码在 `C` 目录中公用。
    - `mock` 中是测试所需要的模拟数据、环境等。
    - `XXX.go` 与 `XXXimpl.go` 是定义与实现的配套代码。
    - 同一事务分别存在于不同主题下，如 `protos` 目录下的 `peer` 与 `core` 目录下的 `peer` 都是 `peer` 相关的代码。
- 模块
    - `bccsp`: blockchain cryptographic service provider
    - `events`: 事件相关
    - `core`: 核心功能代码
    - `common`: 全局通用代码
- 无论（概念上或形式上）多么复杂的对象，本质上只是一个结构体和挂载到该结构体一些操作函数。
- 无论对象的初始化多么复杂，其本质也不过是声明后填充该对象中的各个字段的过程而已。
- 挂载到该对象的函数无论多复杂，也不过是对该对象中的成员所承载的数据进行增、删、改、查操作。
- 根据 Fabric 的惯例，有 `Provider` 字样的对象，或大或小，都是某一主题模块服务的提供者，提供该主题模块的一系列操作服务。
- 接口类型的 `Provider` 对象，则在具体实现上则会分为多种具体的 `Provider` 以供使用（同时也留下了扩展空间）。
- 根据 Fabric 惯例，在每个定义对象结构的文件里，通常都会有一个专门用于生成该对象的函数。