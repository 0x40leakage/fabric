<!-- https://blog.csdn.net/idsuf698987/article/details/77044436 -->

- Endorser 在一个交易中的作用如下：
    1. 客户端发送一个背书请求（`SignedProposal`）到 Endorser。
    2. Endorser 对请求进行背书，发送一个请求应答（`ProposalResponse`）到客户端。
    3. 客户端将请求应答中的背书组装到一个交易请求（`SignedTransaction`）中。
- Endorser
	
    ```go
    // Register the Endorser server
    serverEndorser := endorser.NewEndorserServer()
    pb.RegisterEndorserServer(peerServer.Server(), serverEndorser)
    
    // NewEndorserServer creates and returns a new Endorser server instance.
    func NewEndorserServer(privDist privateDataDistributor, s Support, pr *platforms.Registry, metricsProv metrics.Provider) *Endorser {
        e := &Endorser{
            distributePrivateData: privDist,
            s:                     s,
            PlatformRegistry:      pr,
            PvtRWSetAssembler:     &rwSetAssembler{},
            Metrics:               NewEndorserMetrics(metricsProv),
        }
        return e
    }


    service Endorser {
        rpc ProcessProposal(SignedProposal) returns (ProposalResponse) {}
    }
    // EndorserServer is the server API for Endorser service.
    type EndorserServer interface {
        ProcessProposal(context.Context, *SignedProposal) (*ProposalResponse, error)
    }

    func RegisterEndorserServer(s *grpc.Server, srv EndorserServer) {
        s.RegisterService(&_Endorser_serviceDesc, srv)
    }
    // Endorser provides the Endorser service ProcessProposal
    type Endorser struct {
        policyChecker policy.PolicyChecker
    }
    // NewEndorserServer creates and returns a new Endorser server instance.
    func NewEndorserServer() pb.EndorserServer {
        e := new(Endorser)
        e.policyChecker = policy.NewPolicyChecker(
            peer.NewChannelPolicyManagerGetter(),
            mgmt.GetLocalMSP(),
            mgmt.NewLocalMSPPrincipalGetter(),
        )

        return e
    }
    // ProcessProposal process the Proposal
    func (e *Endorser) ProcessProposal(ctx context.Context, signedProp *pb.SignedProposal) (*pb.ProposalResponse, error) {

    //endorse the proposal by calling the ESCC
    func (e *Endorser) endorseProposal(ctx context.Context, chainID string, txid string, signedProp *pb.SignedProposal, proposal *pb.Proposal, response *pb.Response, simRes []byte, event *pb.ChaincodeEvent, visibility []byte, ccid *pb.ChaincodeID, txsim ledger.TxSimulator, cd *ccprovider.ChaincodeData) (*pb.ProposalResponse, error) {
    ```

- 流程
	
    ```go
    // at first, we check whether the message is valid
    prop, hdr, hdrExt, err := validation.ValidateProposalMessage(signedProp)
    // validate the header
    chdr, shdr, err := validateCommonHeader(hdr)
    // validate the signature
    err = checkSignatureFromCreator(shdr.Creator, signedProp.Signature, signedProp.ProposalBytes, chdr.ChannelId)
    // Verify that the transaction ID has been computed properly.
	// This check is needed to ensure that the lookup into the ledger
	// for the same TxID catches duplicates.
	err = utils.CheckTxID(
		chdr.TxId,
		shdr.Nonce,
        shdr.Creator)
    // validation of the proposal message knowing it's of type CHAINCODE
    chaincodeHdrExt, err := validateChaincodeProposalMessage(prop, hdr)

    shdr, err := putils.GetSignatureHeader(hdr.SignatureHeader)
    // block invocations to security-sensitive system chaincodes
	if syscc.IsSysCCAndNotInvokableExternal(hdrExt.ChaincodeId.Name) {

    // Check for uniqueness of prop.TxID with ledger
	// Notice that ValidateProposalMessage has already verified
    // that TxID is computed properly
    
    // obtaining once the tx simulator for this proposal. This will be nil
	// for chainless proposals
	// Also obtain a history query executor for history queries, since tx simulator does not cover history
    ```

- 策略检查器
	
    ```go
    // NewEndorserServer creates and returns a new Endorser server instance.
    func NewEndorserServer() pb.EndorserServer {
        e := new(Endorser)
        e.policyChecker = policy.NewPolicyChecker(
            peer.NewChannelPolicyManagerGetter(),
            mgmt.GetLocalMSP(),
            mgmt.NewLocalMSPPrincipalGetter(),
        )
        return e
    }
    // fabric/core/policy
    // fabric/core/policyprovider
    // fabric/common/cauthdsl
    // fabric/common/policies
    // fabric/protos/common/policies.proto
    // fabric/protos/common/policies.pb.go

    // FromString takes a string representation of the policy,
    // parses it and returns a SignaturePolicyEnvelope that
    // implements that policy. The supported language is as follows
    //
    // GATE(P[, P])
    //
    // where
    //	- GATE is either "and" or "or"
    //	- P is either a principal or another nested call to GATE
    //
    // a principal is defined as
    //
    // ORG.ROLE
    //
    // where
    //	- ORG is a string (representing the MSP identifier)
    //	- ROLE is either the string "member" or the string "admin" representing the required role

    // CheckPolicyBySignedData checks that the passed signed data is valid with the respect to
    // passed policy on the passed channel.
    func (p *policyChecker) CheckPolicyBySignedData(channelID, policyName string, sd []*common.SignedData) error {

    // Get Policy
    policyManager, _ := p.channelPolicyManagerGetter.Manager(channelID
    // Recall that get policy always returns a policy object
    policy, _ := policyManager.GetPolicy(policyName))
    // Evaluate the policy
	err := policy.Evaluate(sd)
    ```
