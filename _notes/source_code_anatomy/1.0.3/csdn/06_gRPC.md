<!-- https://blog.csdn.net/idsuf698987/article/details/75807973 -->

- `fabric/core/comm/server.go` 定义了安全配置项，`GPRCServer` 的接口、实现和初始化函数，Fabric 默认不使用 tls。

    ```go
    // A SecureServerConfig structure is used to configure security (e.g. TLS) for a GRPCServer instance
    type SecureServerConfig struct {
        // PEM-encoded X509 public key to be used by the server for TLS communication
        // core.yaml 中指定，读取的 tls 目录下 server.cert 存储于此
        ServerCertificate []byte
        // PEM-encoded private key to be used by the server for TLS communication
        // core.yaml 中指定，读取的 tls 目录下 server.key 存储于此
        ServerKey []byte
        // Set of PEM-encoded X509 certificate authorities to optionally send as part of the server handshake
        // core.yaml 中指定，读取的 tls 目录下 ca.crt 存储于此
        ServerRootCAs [][]byte
        // Set of PEM-encoded X509 certificate authorities to use when verifying client certificates
        ClientRootCAs [][]byte
        // Whether or not to use TLS for communication
        UseTLS bool
        // Whether or not TLS client must present certificates for authentication
        RequireClientCert bool
    }

    // GRPCServer defines an interface representing a GRPC-based server
    type GRPCServer interface {
        // Address returns the listen address for the GRPCServer
        Address() string
        // Start starts the underlying grpc.Server
        Start() error
        // Stop stops the underlying grpc.Server
        Stop()
        // Server returns the grpc.Server instance for the GRPCServer
        Server() *grpc.Server
        // Listener returns the net.Listener instance for the GRPCServer
        Listener() net.Listener
        // ServerCertificate returns the tls.Certificate used by the grpc.Server
        ServerCertificate() tls.Certificate
        // TLSEnabled is a flag indicating whether or not TLS is enabled for this GRPCServer instance
        TLSEnabled() bool
        // AppendClientRootCAs appends PEM-encoded X509 certificate authorities to
        // the list of authorities used to verify client certificates
        AppendClientRootCAs(clientRoots [][]byte) error
        // RemoveClientRootCAs removes PEM-encoded X509 certificate authorities from
        // the list of authorities used to verify client certificates
        RemoveClientRootCAs(clientRoots [][]byte) error
        // SetClientRootCAs sets the list of authorities used to verify client
        // certificates based on a list of PEM-encoded X509 certificate authorities
        SetClientRootCAs(clientRoots [][]byte) error
    }

    type grpcServerImpl struct {
        // Listen address for the server specified as hostname:port
        address string
        // Listener for handling network requests
        listener net.Listener
        // GRPC server
        server *grpc.Server
        // Certificate presented by the server for TLS communication
        serverCertificate tls.Certificate
        // Key used by the server for TLS communication
        serverKeyPEM []byte
        // List of certificate authorities to optionally pass to the client during
        // the TLS handshake
        serverRootCAs []tls.Certificate
        // lock to protect concurrent access to append / remove
        lock *sync.Mutex
        // Set of PEM-encoded X509 certificate authorities used to populate
        // the tlsConfig.ClientCAs indexed by subject
        clientRootCAs map[string]*x509.Certificate
        // TLS configuration used by the grpc server
        tlsConfig *tls.Config
        // Is TLS enabled?
        tlsEnabled bool
    }
    // NewGRPCServer creates a new implementation of a GRPCServer given a listen address
    func NewGRPCServer(address string, secureConfig SecureServerConfig) (GRPCServer, error) {
        if address == "" {
            return nil, errors.New("Missing address parameter")
        }
        //create our listener
        lis, err := net.Listen("tcp", address)
        if err != nil {
            return nil, err
        }
        return NewGRPCServerFromListener(lis, secureConfig)
    }
    ```

- `peer node start` 启动的 gRPC 服务：`peerServer`，`globalEventsServer`。
## `peerServer`
- 创建 `peerServer`

    ```go
    // serve()
    peerServer, err := peer.CreatePeerServer(listenAddr, secureConfig)

    // CreatePeerServer()
    // CreatePeerServer creates an instance of comm.GRPCServer. This server is used for peer communications
    peerServer, err = comm.NewGRPCServer(listenAddress, secureConfig)

    // NewGRPCServer()
    // NewGRPCServer creates a new implementation of a GRPCServer given a listen address
    //create our listener
	lis, err := net.Listen("tcp", address)
    return NewGRPCServerFromListener(lis, serverConfig)
    
    // NewGRPCServerFromListener()
    // NewGRPCServerFromListener creates a new implementation of a GRPCServer given an existing net.Listener instance using default keepalive
    grpcServer.server = grpc.NewServer(serverOpts...)
	return grpcServer, nil
    ```

- 注册服务

    ```go
    // fabric/core/chaincode/chaincode_support.go
    // ChaincodeSupport responsible for providing interfacing with chaincodes from the Peer.
    type ChaincodeSupport struct {
        runningChaincodes *runningChaincodes
        peerAddress       string
        ccStartupTimeout  time.Duration
        peerNetworkID     string
        peerID            string
        peerTLSCertFile   string
        peerTLSKeyFile    string
        peerTLSSvrHostOrd string
        keepalive         time.Duration
        chaincodeLogLevel string
        shimLogLevel      string
        logFormat         string
        executetimeout    time.Duration
        userRunsCC        bool
        peerTLS           bool
    }

    // fabric/protos/peer/chaincode_shim.proto

    // Interface that provides support to chaincode execution.
    // ChaincodeContext provides the context necessary for the server to respond appropriately.
    service ChaincodeSupport {
        rpc Register(stream ChaincodeMessage) returns (stream ChaincodeMessage) {}
    }

    // fabric/protos/peer/chaincode_shim.pb.go

    // Server API for ChaincodeSupport service

    type ChaincodeSupportServer interface {
        Register(ChaincodeSupport_RegisterServer) error
    }
    func RegisterChaincodeSupportServer(s *grpc.Server, srv ChaincodeSupportServer) {
        s.RegisterService(&_ChaincodeSupport_serviceDesc, srv)
    }

    type ChaincodeSupport_RegisterServer interface {
        Send(*ChaincodeMessage) error
        Recv() (*ChaincodeMessage, error)
        grpc.ServerStream
    }
    type chaincodeSupportRegisterServer struct {
        grpc.ServerStream
    }

    // 注册服务
    registerChaincodeSupport(ccSrv.Server(), ccEpFunc)
    go ccSrv.Start()
    
    func registerChaincodeSupport(grpcServer *grpc.Server, ccEpFunc ccEndpointFunc) {
        // get user mode
        userRunsCC := chaincode.IsDevMode()
        // get chaincode startup timeout
        ccStartupTimeout := viper.GetDuration("chaincode.startuptimeout")
        if ccStartupTimeout < time.Duration(5)*time.Second {
            logger.Warningf("Invalid chaincode startup timeout value %s (should be at least 5s); defaulting to 5s", ccStartupTimeout)
            ccStartupTimeout = time.Duration(5) * time.Second
        } else {
            logger.Debugf("Chaincode startup timeout value set to %s", ccStartupTimeout)
        }
        ccSrv := chaincode.NewChaincodeSupport(ccEpFunc, userRunsCC, ccStartupTimeout)
        //Now that chaincode is initialized, register all system chaincodes.
        scc.RegisterSysCCs()
        pb.RegisterChaincodeSupportServer(grpcServer, ccSrv)
    }
    ```

## `globalEventsServer`
- `EventsServer`
	
    ```go
    // fabric/events/producer/producer.go

    // EventsServer implementation of the Peer service
    type EventsServer struct {
    }
    // singleton - if we want to create multiple servers, we need to subsume events.gEventConsumers into EventsServer
    var globalEventsServer *EventsServer
    // NewEventsServer returns a EventsServer
    func NewEventsServer(bufferSize uint, timeout time.Duration) *EventsServer {
        initializeEvents(bufferSize, timeout)
    }
    // Chat implementation of the Chat bidi streaming RPC function
    func (p *EventsServer) Chat(stream pb.Events_ChatServer) error {
    }
    ```

- 创建 `globalEventsServer`

	
    ```go
    ehubGrpcServer, err := createEventHubServer(secureConfig)

    func createEventHubServer(secureConfig comm.SecureServerConfig) (comm.GRPCServer, error) {
        var lis net.Listener
        var err error
        lis, err = net.Listen("tcp", viper.GetString("peer.events.address"))
        if err != nil {
            return nil, fmt.Errorf("failed to listen: %v", err)
        }

        grpcServer, err := comm.NewGRPCServerFromListener(lis, secureConfig)
        if err != nil {
            logger.Errorf("Failed to return new GRPC server: %s", err)
            return nil, err
        }
        ehServer := producer.NewEventsServer(
            uint(viper.GetInt("peer.events.buffersize")),
            viper.GetDuration("peer.events.timeout"))

        pb.RegisterEventsServer(grpcServer.Server(), ehServer)
        return grpcServer, nil
    }
    ```

- 事件服务
	
    ```go
    // fabric/protos/peer/events.proto

    // Interface exported by the events server
    service Events {
        // event chatting using Event
        rpc Chat(stream SignedEvent) returns (stream Event) {}
    }

    // fabric/protos/peer/events.pb.go
    type Events_ChatServer interface {
        Send(*Event) error
        Recv() (*SignedEvent, error)
        grpc.ServerStream
    }
    type eventsChatServer struct {
        grpc.ServerStream
    }


    pb.RegisterEventsServer(grpcServer.Server(), ehServer)

    // fabric/events/producer/producer.go

    // Chat implementation of the Chat bidi streaming RPC function
    func (p *EventsServer) Chat(stream pb.Events_ChatServer) error {
        handler, err := newEventHandler(stream)
        if err != nil {
            return fmt.Errorf("error creating handler during handleChat initiation: %s", err)
        }
        defer handler.Stop()
        for {
            in, err := stream.Recv()
            if err == io.EOF {
                logger.Debug("Received EOF, ending Chat")
                return nil
            }
            if err != nil {
                e := fmt.Errorf("error during Chat, stopping handler: %s", err)
                logger.Error(e.Error())
                return e
            }
            err = handler.HandleMessage(in)
            if err != nil {
                logger.Errorf("Error handling message: %s", err)
                return err
            }
        }
    }

    // HandleMessage handles the Openchain messages for the Peer.
    func (d *handler) HandleMessage(msg *pb.SignedEvent) error {
        evt, err := validateEventMessage(msg)
        if err != nil {
            return fmt.Errorf("event message must be properly signed by an identity from the same organization as the peer: [%s]", err)
        }

        switch evt.Event.(type) {
        case *pb.Event_Register:
            eventsObj := evt.GetRegister()
            if err := d.register(eventsObj.Events); err != nil {
                return fmt.Errorf("could not register events %s", err)
            }
        case *pb.Event_Unregister:
            eventsObj := evt.GetUnregister()
            if err := d.deregister(eventsObj.Events); err != nil {
                return fmt.Errorf("could not unregister events %s", err)
            }
        case nil:
        default:
            return fmt.Errorf("invalide type from client %T", evt.Event)
        }
        // TODO return supported events.. for now just return the received msg
        if err := d.ChatStream.Send(evt); err != nil {
            return fmt.Errorf("error sending response to %v:  %s", msg, err)
        }

        return nil
    }
    ```

- 启动事件服务
	
    ```go
    // Start the event hub server
	if ehubGrpcServer != nil {
		go ehubGrpcServer.Start()
    }
    // Start starts the underlying grpc.Server
    func (gServer *GRPCServer) Start() error {
        return gServer.server.Serve(gServer.listener)
    }
    ```

## `eventProcessor`
- `eventProcessor`
	
    ```go
    // fabric/events/producer/events.go

    // eventProcessor has a map of event type to handlers interested in that
    // event type. start() kicks of the event processor where it waits for Events
    // from producers. We could easily generalize the one event handling loop to one
    // per handlerMap if necessary.
    type eventProcessor struct {
        sync.RWMutex
        eventConsumers map[pb.EventType]handlerList

        // we could generalize this with mutiple channels each with its own size
        eventChannel chan *pb.Event

        // timeout duration for producer to send an event.
        // if < 0, if buffer full, unblocks immediately and not send
        // if 0, if buffer full, will block and guarantee the event will be sent out
        // if > 0, if buffer full, blocks till timeout
        timeout time.Duration
    }

    // global eventProcessor singleton created by initializeEvents. Openchain producers
    // send events simply over a reentrant static method
    var gEventProcessor *eventProcessor
    // initialize and start
    func initializeEvents(bufferSize uint, tout time.Duration) {
        if gEventProcessor != nil {
            panic("should not be called twice")
        }
        gEventProcessor = &eventProcessor{eventConsumers: make(map[pb.EventType]handlerList), eventChannel: make(chan *pb.Event, bufferSize), timeout: tout}
        addInternalEventTypes()
        // start the event processor
        go gEventProcessor.start()
    }

    // handlerList uses map to implement a set of handlers. use mutex to access
    // the map. Note that we don't have lock/unlock wrapper methods as the lock
    // of handler list has to be done under the eventProcessor lock. See
    // registerHandler, deRegisterHandler. register/deRegister methods
    // will be called only when a new consumer chat starts/ends respectively
    // and the big lock should have no performance impact
    type handlerList interface {
        add(ie *pb.Interest, h *handler) (bool, error)
        del(ie *pb.Interest, h *handler) (bool, error)
        foreach(ie *pb.Event, action func(h *handler))
    }
    type genericHandlerList struct {
        sync.RWMutex
        handlers map[*handler]bool
    }
    type chaincodeHandlerList struct {
        sync.RWMutex
        handlers map[string]map[string]map[*handler]bool
    }
    ```

## 事件类型

```go
// should be called at init time to register supported internal events
func addInternalEventTypes() {
	AddEventType(pb.EventType_BLOCK)
	AddEventType(pb.EventType_CHAINCODE)
	AddEventType(pb.EventType_REJECTION)
	AddEventType(pb.EventType_REGISTER)
}
```


















































- gRPC 流程：
    - 写 proto，定义 service。
    - 生成对应的 pb.go，得到待接口和可供调用的函数。
    - server 端引用 pb.go，实现接口，调用生成的函数注册 gRPC server，调用 gRPC 方法启动 server 服务。
    - client 端引用 pb.go，调用接口。
        - [ ] [context](https://blog.golang.org/context)
    <!-- - https://github.com/grpc/grpc-go/tree/master/examples/helloworld -->
<!-- https://grpc.io/docs/quickstart/go/ -->
- As in many RPC systems, gRPC is based around the idea of defining a service, specifying the methods that can be called remotely with their parameters and return types. 
    - On the server side, the server implements this interface and runs a gRPC server to handle client calls. 
    - On the client side, the client has a stub (referred to as just a client in some languages) that provides the same methods as the server.

    ```protobuf
    service HelloService {
        rpc SayHello (HelloRequest) returns (HelloResponse);
    }

    message HelloRequest {
        string greeting = 1;
    }

    message HelloResponse {
        string reply = 1;
    }
    ```

- Starting from a service definition in a `.proto` file, gRPC provides protocol buffer compiler plugins that generate client- and server-side code. gRPC users typically call these APIs on the client side and implement the corresponding API on the server side.
    - On the server side, the server implements the methods declared by the service and runs a gRPC server to handle client calls. The gRPC infrastructure decodes incoming requests, executes service methods, and encodes service responses.
    - On the client side, the client has a local object known as *stub* that implements the same methods as the service. The client can then just call those methods on the local object, wrapping the parameters for the call in the appropriate protocol buffer message type - gRPC looks after sending the request(s) to the server and returning the server’s protocol buffer response(s).
- Synchronous RPC calls that block until a response arrives from the server are the closest approximation to the abstraction of a procedure call that RPC aspires to. On the other hand, networks are inherently asynchronous and in many scenarios it’s useful to be able to start RPCs without blocking the current thread.
- gRPC lets you define 4 kinds of service method:
    1. Unary RPCs where the client sends a single request to the server and gets a single response back, just like a normal function call.
    
        ```protobuf
        rpc SayHello(HelloRequest) returns (HelloResponse){
        }
        ```
        
    2. Server streaming RPCs where the client sends a request to the server and gets a stream to read a sequence of messages back. The client reads from the returned stream until there are no more messages. gRPC guarantees message ordering within an individual RPC call.

        ```protobuf
        rpc LotsOfReplies(HelloRequest) returns (stream HelloResponse){
        }
        ```
    
    3. Client streaming RPCs where the client writes a sequence of messages and sends them to the server, again using a provided stream. Once the client has finished writing the messages, it waits for the server to read them and return its response. Again gRPC guarantees message ordering within an individual RPC call.

        ```protobuf
        rpc LotsOfGreetings(stream HelloRequest) returns (HelloResponse) {
        }
        ```
    
    4. Bidirectional streaming RPCs where both sides send a sequence of messages using a read-write stream. The two streams operate independently, so clients and servers can read and write in whatever order they like: for example, the server could wait to receive all the client messages before writing its responses, or it could alternately read a message then write a message, or some other combination of reads and writes. The order of messages in each stream is preserved.

        ```protobuf
        rpc BidiHello(stream HelloRequest) returns (stream HelloResponse){
        }
        ```

- RPC life cycle
    1. Unary RPC
        - Once the client calls the method on the stub/client object, the server is **notified** (before receiving the actual request) that the RPC has been invoked with the client’s *metadata* for this call, the method name, and the specified *deadline* if applicable.
        - The server can then either send back its own initial metadata (which **must be sent before any response**) straight away, or wait for the client’s request message - which happens first is application-specific.
        - Once the server has the client’s request message, it does whatever work is necessary to create and populate its response. The response is then returned (if successful) to the client together with status details (status code and optional status message) and optional trailing metadata.
        - If the status is OK, the client then gets the response, which completes the call on the client side.
    2. Server streaming RPC
        - A server-streaming RPC is similar to our simple example, except the server sends back a stream of responses after getting the client’s request message. 
            - After sending back all its responses, the server’s status details (status code and optional status message) and optional trailing metadata are sent back to complete on the server side.
            - The client completes once it has all the server’s responses.
    3. Client streaming RPC
        - A client-streaming RPC is also similar to our simple example, except the client sends a stream of requests to the server instead of a single request. 
            - The server sends back a single response, typically but not necessarily after it has received all the client’s requests, along with its status details and optional trailing metadata.
    4. Bidirectional streaming RPC
        - In a bidirectional streaming RPC, again the call is initiated by the client calling the method and the server receiving the client metadata, method name, and deadline. Again the server can choose to send back its initial metadata or wait for the client to start sending requests.
        - What happens next depends on the application, as the client and server can read and write in any order - the streams operate completely independently. 
            - So, for example, the server could wait until it has received all the client’s messages before writing its responses, or the server and client could “ping-pong”: the server gets a request, then sends back a response, then the client sends another request based on the response, and so on.
- Deadlines/Timeouts
    - gRPC allows clients to specify how long they are willing to wait for an RPC to complete before the RPC is terminated with the error `DEADLINE_EXCEEDED`. 
    - On the server side, the server can query to see if a particular RPC has timed out, or how much time is left to complete the RPC.
    - How the deadline or timeout is specified varies from language to language - for example, not all languages have a default deadline, some language APIs work in terms of a deadline (a fixed point in time), and some language APIs work in terms of timeouts (durations of time).
- RPC termination
    - In gRPC, both the client and server make independent and local determinations of the success of the call, and their conclusions may not match. 
    - This means that, for example, you could have an RPC that finishes successfully on the server side (“I have sent all my responses!”) but fails on the client side (“The responses arrived after my deadline!“). 
    - It’s also possible for a server to decide to complete before a client has sent all its requests.
- Cancelling RPCs
    - Either the client or the server can cancel an RPC at any time.
    - A cancellation terminates the RPC immediately so that no further work is done. 
    - It is **not an “undo”**: changes made before the cancellation will not be rolled back.
- Metadata
    - Metadata is information about a particular RPC call (such as authentication details) in the form of a list of key-value pairs, where the keys are strings and the values are typically strings (but can be binary data). 
    - **Metadata is opaque to gRPC itself** - it lets the client provide information associated with the call to the server and vice versa.
    - Access to metadata is language-dependent.
- Channels
    - A gRPC channel provides a **connection** to a gRPC server **on a specified host and port** and is used when creating a client stub. 
    - Clients can specify channel arguments to modify gRPC’s default behaviour, such as switching on and off message compression. 
    - A channel has state, including connected and idle.
    - How gRPC deals with closing down channels is language-dependent. 
    - Some languages also permit querying channel state.