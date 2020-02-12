peer1 的数字证书的颁发者是 CA1，peer1 连接 channel 时，channel MSP 中定义的策略显示 CA1 是与 Org1（Org1.MSP) 关联的，从而确定 peer1 在 Org1 中的角色（role）和对区块链网络资源的访问权限。  

任何与区块链网络交互的实体都通过数字证书和 MSP 来获得其在组织中的身份。

- [ ] MSP 可以给他人吗，是否给到他人后可以冒充身份
    - 只给 msp 目录，不给私钥
- [ ] 解码 X.509 的 pem 证书

The different actors in a blockchain network include peers, orderers, client applications, administrators and more. Each of these actors — active elements inside or outside a network able to consume services — has a digital identity encapsulated in an *X.509* digital certificate.  

*Principal*: the union of an identity and the associated attributes.  

For an identity to be **verifiable**, it must come from a trusted authority. A membership service provider (MSP) is how this is achieved in Fabric. More specifically, an MSP is a component that defines the rules that govern the valid identities for this organization. 

The default MSP implementation in Fabric uses X.509 certificates as identities, adopting a traditional Public Key Infrastructure (PKI) hierarchical model.  
A PKI provides a list of identities, and an MSP says which of these are members of a given organization that participates in the network.  

MSPs turn verifiable identities into the members of a blockchain network.

A PKI is comprised of Certificate Authorities who issue digital certificates to parties (e.g., users of a service, service provider), who then use them to **authenticate** themselves in the messages they exchange with their **environment**.  
A CA’s Certificate Revocation List (CRL) constitutes a reference for the certificates that are no longer valid. 

For a digital certificate describing a party called Mary Morris, Mary is the `SUBJECT` of the certificate, and the `SUBJECT` shows key facts about Mary. Mary’s public key is distributed within her certificate, whereas her private signing key is not. This signing key must be kept private.  
Cryptography allows Mary to present her certificate to others to prove her identity so long as the other party trusts the certificate issuer, known as a Certificate Authority (CA). As long as the CA keeps certain cryptographic information securely (meaning, its own private signing key), anyone reading the certificate can be sure that the information about Mary has not been tampered with — it will always have those particular attributes for Mary Morris. Think of Mary’s X.509 certificate as a digital identity card that is impossible to change.

**Authentication** requires that parties who exchange messages are assured of the identity that created a specific message. You might want to be sure you’re communicating with the real Mary Morris rather than an impersonator.  
For a message to have **“integrity”** means that cannot have been modified during its transmission. If Mary has sent you a message, you might want to be sure that it hasn’t been tampered with by anyone else during transmission.   

Traditional authentication mechanisms rely on **digital signatures** that allow a party to digitally sign its messages.   
Digital signatures also provide guarantees on the integrity of the signed message.

Digital signature mechanisms require each party to hold two cryptographically connected keys: a public key that is made widely available and acts as authentication anchor, and a private key that is used to produce digital signatures on messages. Recipients of digitally signed messages can verify the origin and integrity of a received message by checking that the attached signature is valid under the public key of the expected sender.  
The unique relationship between a private key and the respective public key is the cryptographic magic that makes secure communications possible. The unique mathematical relationship between the keys is such that the private key can be used to produce a signature on a message that only the corresponding public key can match, and only on the same message.（数字签名非加密，信息内容是明文）

An actor or a node is able to participate in the blockchain network, via the means of a digital identity issued for it by an authority trusted by the system.   
In the most common case, digital identities (or simply identities) have the form of cryptographically validated digital certificates that comply with X.509 standard and are issued by a Certificate Authority (CA).  

A Certificate Authority dispenses certificates to different actors. These certificates are digitally signed by the CA and bind together the actor with the actor’s public key (and optionally with a comprehensive list of properties). As a result, if one trusts the CA (and knows its public key), it can trust that the specific actor is bound to the public key included in the certificate, and owns the included attributes, by validating the CA’s signature on the actor’s certificate.（申请者将自己的公钥和其他信息给到 CA 申请证书；颁发证书时，CA 用自己的私钥对申请者的公钥和其他信息进行数字签名）  
CAs also have a certificate, which they make widely available. This allows the consumers of identities issued by a given CA to verify them by checking that the certificate could only have been generated by the holder of the corresponding private key (the CA).  
数字证书的目的是让公钥经过权威第三方的背书，使该公钥等同于申请者的数字身份，其他人通过数字证书确认通信的对方确实是通信的目标。信息的完整性由非对称加密的机制来保证。  

Because Root CAs (Symantec, Geotrust, etc) have to securely distribute hundreds of millions of certificates to internet users, it makes sense to spread this process out across what are called Intermediate CAs. These Intermediate CAs have their certificates issued by the root CA or another intermediate authority, allowing the establishment of a “chain of trust” for any certificate that is issued by any CA in the chain. This ability to track back to the Root CA not only allows the function of CAs to **scale** while still providing security — allowing organizations that consume certificates to use Intermediate CAs with confidence — it **limits the exposure of the Root CA**, which, if compromised, would endanger the entire chain of trust.

Fabric CA is a private root CA provider capable of managing digital identities of Fabric participants that have the form of X.509 certificates. Because Fabric CA is a custom CA targeting the **Root CA** needs of Fabric, it is inherently not capable of providing SSL certificates for general/automatic use in browsers. However, because some CA must be used to manage identity (even in a test environment), Fabric CA can be used to provide and manage certificates. It is also possible — and fully appropriate — to use a public/commercial root or intermediate CA to provide identification.  

When a third party wants to verify another party’s identity, it first checks the issuing CA’s CRL to make sure that the certificate has not been revoked.  

MSP identifies which Root CAs and Intermediate CAs are trusted to define the members of a trust domain, e.g., an organization, either by listing the identities of their members, or by identifying which CAs are authorized to issue valid identities for their members, or — as will usually be the case — through a combination of both.  

The configuration of an MSP is advertised to all the channels where members of the corresponding organization participate (in the form of a *channel MSP*). In addition to the channel MSP, peers, orderers, and clients also maintain a *local MSP* to authenticate member messages outside the context of a channel and to define the permissions over a particular component (who has the ability to install chaincode on a peer, for example).  
In addition, an MSP can allow for the identification of a list of identities that have been revoked.  

An organization is a managed group of members.  
Organizations manage their members under a single MSP. Note that this is different from the organization concept defined in an X.509 certificate.

The exclusive relationship between an organization and its MSP makes it sensible to name the MSP after the organization, a convention you’ll find adopted in most policy configurations. In some cases an organization may require multiple membership groups — for example, where channels are used to perform very different business functions between organizations.  
![](src/msp.png)  

An organization is often divided up into multiple *organizational units* (OUs), each of which has a certain set of responsibilities. For example, the `ORG1` organization might have both `ORG1-MANUFACTURING` and `ORG1-DISTRIBUTION` OUs to reflect these separate lines of business.  
When a CA issues X.509 certificates, the `OU` field in the certificate specifies the line of business to which the identity belongs.  
Though this is a slight misuse of OUs, they can sometimes be used by different organizations in a consortium to distinguish each other. In such cases, the different organizations use the same Root CAs and Intermediate CAs for their chain of trust, but assign the OU field to identify members of each organization.  

MSPs appear in two places in a blockchain network: channel configuration (channel MSPs), and locally on an actor’s premise (local MSP).  

Local MSPs are defined for clients (users) and for nodes (peers and orderers). Node local MSPs define the permissions for that node (who the peer admins are, for example). The local MSPs of the users allow the user side to authenticate itself in its transactions as a member of a channel (e.g. in chaincode transactions), or as the owner of a specific role into the system (an org admin, for example, in configuration transactions).  
Every node and user must have a local MSP defined, as it defines who has administrative or participatory rights at that level (peer admins will not necessarily be channel admins, and vice versa).  

Channel MSPs define administrative and participatory rights at the channel level. Every organization participating in a channel must have an MSP defined for it.   
**Peers and orderers on a channel will all share the same view of channel MSPs**, and will therefore be able to correctly authenticate the channel participants. This means that if an organization wishes to join the channel, an MSP incorporating the chain of trust for the organization’s members would need to be included in the channel configuration. Otherwise transactions originating from this organization’s identities will be rejected. 

The key difference here between local and channel MSPs is not how they function — both **turn identities into *roles*** — but their **scope**.  

Representation of an organization on a channel is achieved by adding the organization’s MSP to the channel configuration.  

![](src/msp_instantiate.png)  
An administrator B connects to the peer with an identity issued by RCA1 and stored in their local MSP. When B tries to install a smart contract on the peer, the peer checks its local MSP, `ORG1-MSP`, to verify that the identity of B is indeed a member of ORG1. A successful verification will allow the install command to complete successfully.  
Subsequently, B wishes to instantiate the smart contract on the channel. Because this is a channel operation, all organizations on the channel must agree to it. Therefore, the peer must check the MSPs of the channel before it can successfully commit this command. (Other things must happen too, but concentrate on the above for now.)  
Local MSPs are only defined on the file system of the node or user to which they apply. Therefore, physically and logically there is only one local MSP per node or user.  
As channel MSPs are available to all nodes in the channel, they are logically defined once in the channel configuration. However, a channel MSP is also instantiated on the file system of every node in the channel and kept synchronized via consensus. So while there is a copy of each channel MSP on the local file system of every node, logically a channel MSP resides on and is maintained by the channel or the network.

It’s helpful to think of these MSPs as being at different levels, with MSPs at a higher level relating to network administration concerns while MSPs at a lower level handle identity for the administration of private resources. MSPs are mandatory at every level of administration — they must be defined for the network, channel, peer, orderer, and users.  
The MSPs for the peer and orderer are local, whereas the MSPs for a channel (including the network configuration channel) are shared across all participants of that channel.  

Network MSP: The configuration of a network defines who are the members in the network — by defining the MSPs of the participant organizations — as well as which of these members are authorized to perform administrative tasks (e.g., creating a channel).  
Channel MSP: A channel provides private communications between a particular set of organizations which in turn have administrative control over it. **Channel policies** interpreted in the context of that channel’s MSPs define who has ability to participate in certain action on the channel, e.g., adding organizations, or instantiating chaincodes. Note that there is no necessary relationship between the permission to administrate a channel and the ability to administrate the network configuration channel (or any other channel). Administrative rights exist within the scope of what is being administrated (unless the rules have been written otherwise — see the discussion of the `ROLE` attribute below).  
Peer MSP: This local MSP is defined on the file system of each peer and **there is a single MSP instance for each peer**. Conceptually, it performs exactly the same function as channel MSPs with the restriction that it **only applies to the peer where it is defined**. An example of an action whose authorization is evaluated using the peer’s local MSP is the **installation** of a chaincode on the peer.  
Orderer MSP: Like a peer MSP, an orderer local MSP is also defined on the file system of the node and only applies to that node. Like peer nodes, orderers are also owned by a single organization and therefore have a single MSP to list the actors or nodes it trusts.  

# MSP Structure
Root CAs: This folder contains a list of **self-signed** X.509 certificates of the Root CAs trusted by the organization represented by this MSP. There must be at least one Root CA X.509 certificate in this MSP folder.  
This is the most important folder because it identifies the CAs from which all other certificates must be derived to be considered members of the corresponding organization.

Intermediate CAs: This folder contains a list of X.509 certificates of the Intermediate CAs trusted by this organization. Each certificate must be signed by one of the Root CAs in the MSP or by an Intermediate CA whose issuing CA chain ultimately leads back to a trusted Root CA.  
An intermediate CA may represent a different subdivision of the organization (like ORG1-MANUFACTURING and ORG1-DISTRIBUTION do for ORG1), or the organization itself (as may be the case if a **commercial CA** is leveraged for the organization’s identity management).  
It is possible to have a functioning network that does not have an Intermediate CA, in which case this folder would be empty.

Organizational Units (OUs): These are listed in the `$FABRIC_CFG_PATH/msp/config.yaml` file and contain a list of organizational units, whose members are considered to be part of the organization represented by this MSP. This is particularly useful when you want to restrict the members of an organization to the ones holding an identity (signed by one of MSP designated CAs) with a specific OU in it.  
Specifying OUs is optional. If no OUs are listed, all the identities that are part of an MSP — as identified by the Root CA and Intermediate CA folders — will be considered members of the organization.  

Administrators: This folder contains a list of identities that define the actors who have the role of administrators for this organization. For the standard MSP type, there should be one or more X.509 certificates in this list.  
It’s worth noting that just because an actor has the role of an administrator it doesn’t mean that they can administer particular resources! The actual power a given identity has with respect to administering the system is determined by the policies that manage system resources.  
Even though an X.509 certificate has a `ROLE` attribute (specifying, for example, that an actor is an admin), this refers to an actor’s **role within its organization rather than on the blockchain network**. This is similar to the purpose of the `OU` attribute, which — if it has been defined — refers to an actor’s place in the organization.  
The `ROLE` attribute can be used to confer administrative rights at the channel level if the policy for that channel has been written to allow any administrator from an organization (or certain organizations) permission to perform certain channel functions (such as instantiating chaincode). In this way, an organizational role can confer a network role.  

Revoked Certificates: If the identity of an actor has been revoked, identifying information about the identity — not the identity itself — is held in this folder. For X.509-based identities, these identifiers are pairs of strings known as *Subject Key Identifier* (SKI) and *Authority Access Identifier* (AKI), and are checked whenever the X.509 certificate is being used to make sure the certificate has not been revoked.  
This list is conceptually the same as a CA’s Certificate Revocation List (CRL), but it also relates to revocation of membership from the organization. As a result, the administrator of an MSP, local or channel, can quickly revoke an actor or node from an organization by advertising the updated CRL of the CA the revoked certificate as issued by. This “list of lists” is optional. It will only become populated as certificates are revoked.  

Node Identity: This folder contains the identity of the node, i.e., cryptographic material that — in combination to the content of KeyStore — would allow the node to authenticate itself in the messages that is sends to other participants of its channels and network. For X.509 based identities, this folder contains an X.509 certificate. This is the certificate **a peer places in a transaction proposal response**, for example, to indicate that the peer has endorsed it — which can subsequently be checked against the resulting transaction’s endorsement policy at validation time.  
This folder is mandatory for local MSPs, and there must be exactly one X.509 certificate for the node. It is not used for channel MSPs.  

KeyStore for Private Key: This folder is defined for the local MSP of a peer or orderer node (or in an client’s local MSP), and contains the node’s signing key. This key cryptographically matches the node’s identity included in Node Identity folder and is used to sign data — for example to sign a transaction proposal response, as part of the endorsement phase.  
This folder is mandatory for local MSPs, and must contain exactly one private key. Obviously, access to this folder must be limited only to the identities of users who have administrative responsibility on the peer.  
Configuration of a channel MSPs does not include this folder, as channel MSPs solely aim to offer identity validation functionalities and not signing abilities.  

TLS Root CA: This folder contains a list of **self-signed** X.509 certificates of the Root CAs trusted by this organization for TLS communications. An example of a TLS communication would be when a peer needs to connect to an orderer so that it can receive ledger updates.  
MSP TLS information relates to the nodes inside the network — the peers and the orderers rather than the applications and administrations that consume the network.  
There must be at least one TLS Root CA X.509 certificate in this folder.  

TLS Intermediate CA: This folder contains a list intermediate CA certificates CAs trusted by the organization represented by this MSP for TLS communications. This folder is specifically useful when commercial CAs are used for TLS certificates of an organization. Similar to membership intermediate CAs, specifying intermediate TLS CAs is optional.