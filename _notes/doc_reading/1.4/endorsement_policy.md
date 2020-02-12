<!-- https://hyperledger-fabric.readthedocs.io/en/release-1.4/endorsement-policies.html -->

- Every chaincode has an endorsement policy which specifies the set of peers on a channel that must execute chaincode and endorse the execution results in order for the transaction to be considered valid. These endorsement policies define the organizations (through their peers) who must “endorse” (i.e., approve of) the execution of a proposal.
- As part of the transaction validation step performed by the peers, each validating peer checks to make sure that the transaction contains the appropriate number of endorsements and that they are from the expected sources (both of these are specified in the endorsement policy). 
- The endorsements are also checked to make sure they’re valid (i.e., that they are valid signatures from valid certificates).
- By default, endorsement policies are specified for a channel’s chaincode at instantiation or upgrade time (that is, one endorsement policy covers all of the state associated with a chaincode).
- There are cases where it may be necessary for a particular state (a particular key-value pair, in other words) to have a different endorsement policy. This state-based endorsement allows the default chaincode-level endorsement policies to be overridden by a different policy for the specified keys.
    - An endorsement policy is required for a particular asset that is different from the default endorsement policies for the other assets associated with that chaincode.
- If the [identity classification](https://hyperledger-fabric.readthedocs.io/en/release-1.4/msp.html#identity-classification) is enabled, one can use the `PEER` role to restrict endorsement to only peers.
- If not specified at instantiation time, the endorsement policy defaults to “any member of the organizations in the channel”. 
    - For example, a channel with `Org1` and `Org2` would have a default endorsement policy of `OR(‘Org1.member’, ‘Org2.member’)`.
- Syntax: `EXPR(E[, E...])`.
    - `EXPR` is either `AND`, `OR`, or `OutOf`, and `E` is either a principal or another nested call to `EXPR`.
    - Principals (identities matched to a role) are described as `MSP.ROLE`, where MSP represents the required MSP ID and `ROLE` represents one of the four accepted roles: `member`, `admin`, `client`, and `peer`.
    - Examples:
        - `AND('Org1.member', 'Org2.member', 'Org3.member')` requests 1 signature from each of the 3 principals.
        - `OR('Org1.member', AND('Org2.member', 'Org3.member'))`
        - `OutOf(1, 'Org1.member', 'Org2.member')` resolves to the same thing as `OR('Org1.member', 'Org2.member')`.
        - `OutOf(2, 'Org1.member', 'Org2.member')` is equivalent to `AND('Org1.member', 'Org2.member')`
        - `OutOf(2, 'Org1.member', 'Org2.member', 'Org3.member')` is equivalent to `OR(AND('Org1.member', 'Org2.member')`, `AND('Org1.member', 'Org3.member')`, `AND('Org2.member', 'Org3.member'))`.
- Setting regular chaincode-level endorsement policies is **tied to the lifecycle of the corresponding chaincode**. They can only be set or modified when instantiating or upgrading the corresponding chaincode on a channel.
- Key-level endorsement policies can be set and modified in a more granular fashion from within a chaincode. The modification is **part of the read-write set of a regular transaction**.
- The shim API provides the following functions to set and retrieve an endorsement policy for/from a key.
	
    ```
    SetStateValidationParameter(key string, ep []byte) error
    GetStateValidationParameter(key string) ([]byte, error)

    SetPrivateDataValidationParameter(collection, key string, ep []byte) error
    GetPrivateDataValidationParameter(collection, key string) ([]byte, error)
    ```

    - `ep` stands for the *endorsement policy*, which can be expressed either by using the same syntax described above or by using the convenience function described below. Either method will generate a binary version of the endorsement policy that can be consumed by the basic shim API.
- To help set endorsement policies and marshal them into validation parameter byte arrays, the Go shim provides an extension with convenience functions that allow the chaincode developer to deal with endorsement policies in terms of the MSP identifiers of organization.
	
    ```go
    // fabric/core/chaincode/shim/ext/statebased

    // KeyEndorsementPolicy provides a set of convenience methods to create and
    // modify a state-based endorsement policy. Endorsement policies created by
    // this convenience layer will always be a logical AND of "<ORG>.peer"
    // principals for one or more ORGs specified by the caller.
    type KeyEndorsementPolicy interface {
        // Policy returns the endorsement policy as bytes
        Policy() ([]byte, error)
        // AddOrgs adds the specified orgs to the list of orgs that are required
        // to endorse. All orgs MSP role types will be set to the role that is
        // specified in the first parameter. Among other aspects the desired role
        // depends on the channel's configuration: if it supports node OUs, it is
        // likely going to be the PEER role, while the MEMBER role is the suited
        // one if it does not.
        AddOrgs(roleType RoleType, organizations ...string) error
        // DelOrgs deletes the specified channel orgs from the existing key-level endorsement
        // policy for this KVS key.
        DelOrgs(organizations ...string)
        // ListOrgs returns an array of channel orgs that are required to endorse changes
        ListOrgs() []string
    }
    ```

    - For example, to set an endorsement policy for a key where 2 specific orgs are required to endorse the key change, pass both org MSPIDs to `AddOrgs()`, and then call `Policy()` to construct the endorsement policy byte array that can be passed to `SetStateValidationParameter()`
        - `SetStateValidationParameter(key string, ep []byte) error` sets the key-level endorsement policy for `key`.
    - Add the shim extension to your chaincode as a dependency: [Managing external dependencies for chaincode written in Go](https://hyperledger-fabric.readthedocs.io/en/release-1.4/chaincode4ade.html#vendoring)
- At commit time, setting a value of a key is no different from setting the endorsement policy of a key — both update the state of the key and are validated based on the same rules.
- If a key is modified and no key-level endorsement policy is present, the chaincode-level endorsement policy applies by default. This is also true when a key-level endorsement policy is set for a key for the first time — the new key-level endorsement policy must first be endorsed according to the pre-existing chaincode-level endorsement policy.
- If a key is modified and a key-level endorsement policy is present, the key-level endorsement policy overrides the chaincode-level endorsement policy. In practice, this means that the key-level endorsement policy can be either less restrictive or more restrictive than the chaincode-level endorsement policy. 
    - Because the chaincode-level endorsement policy must be satisfied in order to set a key-level endorsement policy for the first time, no trust assumptions have been violated.
- If a key’s endorsement policy is removed (set to nil), the chaincode-level endorsement policy becomes the default again.
- If a transaction modifies multiple keys with different associated key-level endorsement policies, all of these policies need to be satisfied in order for the transaction to be valid.