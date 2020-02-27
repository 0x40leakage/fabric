[ ] partition

- [Introduction](#introduction)
  - [Topics and Logs](#topics-and-logs)
  - [Distribution](#distribution)
  - [Producers](#producers)
  - [Consumers](#consumers)
# Introduction
Apache Kafka is a *distributed streaming platform*. A streaming platform has three key capabilities:
- **Publish and subscribe** to **streams of records**, similar to a message queue or - enterprise messaging system.
- **Store** streams of records in a **fault-tolerant durable** way.
- Process streams of records as they occur.

Kafka is generally used for two broad classes of applications:
- Building real-time streaming data pipelines that reliably get data between systems or applications
- Building real-time streaming applications that transform or react to the streams of data

A few concepts: 
- Kafka is run as a cluster on one or more servers that can span multiple datacenters.
- The Kafka cluster stores streams of records in **categories** called *topics*.  
- Each record consists of **a key**, **a value**, and **a timestamp**.

Kafka has four core APIs:
1. The `Producer` API allows an application to **publish** a stream of records to one or more Kafka topics.
2. The `Consumer` API allows an application to **subscribe** to one or more topics and process the stream of records produced to them.
3. The `Streams` API allows an application to act as a *stream processor*, consuming an input stream from one or more topics and producing an output stream to one or more output topics, effectively transforming the input streams to output streams.
4. The `Connector` API allows building and running reusable producers or consumers that connect Kafka topics to existing applications or data systems. For example, a connector to a relational database might capture every change to a table.

In Kafka the communication between the clients and the servers is done with a simple, high-performance, language agnostic TCP protocol. This protocol is versioned and maintains backwards compatibility with older version. We provide a Java client for Kafka, but clients are available in many languages.

## Topics and Logs
A *topic* is a **category** or feed name to which records are published.  
Topics in Kafka are always **multi-subscriber**; that is, a topic can have zero, one, or many consumers that subscribe to the data written to it.

For each topic, the Kafka cluster maintains a partitioned log that looks like this:  

![](https://kafka.apache.org/23/images/log_anatomy.png)  

一个 topic 包含多个 partition。  
topic 和 partition 的内容都是 log。

Each partition is an ordered, immutable sequence of records that is continually appended to—**a structured commit *log***. The records in the partitions are each assigned a sequential id number called the *offset* that uniquely identifies each record within the partition.

The Kafka cluster **durably persists** all published records—whether or not they have been consumed—using a **configurable retention period**. For example, if the retention policy is set to two days, then for the two days after a record is published, it is available for consumption, after which it will be discarded to free up space. Kafka's performance is effectively constant with respect to data size so storing data for a long time is not a problem.

The only metadata retained on a per-consumer basis is the offset or position of that consumer in the log. This offset is controlled by the consumer: normally a consumer will advance its offset linearly as it reads records, but, in fact, since the position is controlled by the consumer it can consume records in any order it likes.

This combination of features means that Kafka consumers are very cheap—they can come and go without much impact on the cluster or on other consumers. For example, you can use our command line tools to "tail" the contents of any topic without changing what is consumed by any existing consumers.

The partitions in the log serve several purposes. First, they allow the log to **scale** beyond a size that will fit on a single server. Each individual partition must fit on the servers that host it, but a topic may have many partitions so it can handle an arbitrary amount of data. Second they act as the unit of **parallelism**.
## Distribution
The partitions of the log are distributed over the servers in the Kafka cluster with each server handling data and requests for a share of the partitions. Each partition is **replicated** across a configurable number of servers for fault tolerance.

Each partition has one server which acts as the "leader" and zero or more servers which act as "followers". **The leader handles all read and write requests for the partition while the followers passively replicate the leader**. If the leader fails, one of the followers will automatically become the new leader.  
Each server acts as a leader for some of its partitions and a follower for others so load is well balanced within the cluster.  
leader 是对 partition 而言的。
<!-- ## Geo-Replication -->
## Producers
Producers publish data to the topics of their choice. The producer is responsible for **choosing which record to assign to which partition within the topic**. This can be done in a round-robin fashion simply to balance load or it can be done according to some semantic partition function (say based on some key in the record).
## Consumers
Consumers label themselves with a *consumer group* name, and each record published to a topic is delivered to **one consumer instance** within each subscribing consumer group. Consumer instances can be in separate processes or on separate machines.

If all the consumer instances have the same consumer group, then the records will effectively be load balanced over the consumer instances.   
If all the consumer instances have different consumer groups, then each record will be broadcast to all the consumer processes.

More commonly, however, we have found that topics have a small number of consumer groups, one for each "logical subscriber". Each group is composed of many consumer instances for scalability and fault tolerance.

The way consumption is implemented in Kafka is by dividing up the partitions in the log over the consumer instances so that each instance is the exclusive consumer of a "fair share" of partitions at any point in time. This process of maintaining membership in the group is handled by the Kafka protocol dynamically. If new instances join the group they will take over some partitions from other members of the group; if an instance dies, its partitions will be distributed to the remaining instances.

Kafka only provides a total **order over records within a partition**, not between different partitions in a topic. Per-partition ordering combined with the ability to partition data by key is sufficient for most applications.  
However, if you require a **total order** over records this can be achieved with **a topic that has only one partition**, though this will mean only **one consumer process per consumer group**.


continues https://kafka.apache.org/intro#intro_multi-tenancy