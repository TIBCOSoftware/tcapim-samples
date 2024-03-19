## Capacity planning for TIBCO Cloud™ API Management - Observability stack

### Table of Contents
- [Objective](#objective)
- [Background](#background)
- [Storage requirements](#storage-requirements)
- [Number of nodes](#number-of-nodes)
- [Use case: 100 qps](#use-case-100-qps)
- [Suggested Matrix](#suggested-matrix)
  - [Without debug logs](#without-debug-logs)
  - [With debug logs](#with-debug-logs)
- [Choosing instance types and testing](#choosing-instance-types-and-testing)
- [References](#references)


### Objective
As a part of TIBCO Cloud™ API Management - Local Edition 6.0.0, customers can have their observability stack (like Open search, Elastic search, or Splunk) in their environment, where they can choose to ingest the raw/access logs + application logs generated by TIBCO Cloud™ API Management - Local Edition 6.0.0.

In case the customer does not have an existing observability cluster, then this document provides guidelines about choosing the right observability stack hardware configuration. Choosing the appropriate cluster settings depends on three key co:

- Calculating storage requirements
- Determine the number of nodes
- Choosing instance types and testing 


### Background
Before reading further about the observability cluster, you must know what type of data you receive from TIBCO Cloud™ API Management - Local Edition and the average size of that data.

There are 3 types of data that TIBCO Cloud™ API Management - Local Edition 6.0.0 sends. 

> 1. **Access logs**: These logs are generated by the TIBCO Cloud™ API Management - Local Edition Gateway and contain information about the requests and responses that are processed by the gateway.
> - Volume: X times of QPS
> - Average size: 1.2KB

> 2. **Application logs**: These logs are sent from various applications running in Kubernetes (k8s) pods.
> - Volume: X times of QPS
> - Average size: 1KB ???

> 3. **Debug logs**: These logs are verbose logs depicting request/response headers and payload exchanged among client, APIM and customer backend.
> - Volume: 4x times of QPS
> - Average size: 1MB

### Storage requirements
As you are now aware of the type of data, average size, and volume of data, proceed with the storage calculation. To calculate storage requirements, you must know the following: 

- QPS
- Retention period

Use the following formula to calculate the space required to store source data:

> Daily source data = QPS * 60 seconds * 60 minutes * 24 hours * average size of log

The size of the source data is one aspect. The other aspects while calculating storage requirements are:
- Number of replicas
- Indexing overhead
- Operating system overhead
- Service overhead

- More details about these parameters can be found in this [documentation](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/sizing-domains.html).

Considering all these aspects, you can use a simplified version of this formula:

> Storage needed = daily source data * (1 + number of replicas) * 1.25 * retention period

If you have the same retention for all 3 types of logs, then you can use the above formula as is, otherwise you need to calculate storage for each type of logs separately as per desired retention.

### Number of nodes
The number of nodes is based on the total storage required and the memory and storage of the machine.  It also depends on the performance requirements. 

The general formula to know a number of nodes:
> Total Data Nodes = ROUNDUP(Total storage (GB) / Memory per data node / Memory:Data ratio)

In case of large deployment it's safe to add a node for failover capacity.
Where,
- Total storage
  - storage is calculated by using the above formula
- Memory per data node
  - RAM which you want to allocate per Data node(DN)
- Memory:Data ratio
  - This is RAM to disk/EBS ratio. 
  - The typical memory:data ratio for the hot zone used is 1:30 and for the warm zone is 1:160. Refer [this](https://www.elastic.co/guide/en/elasticsearch/reference/current/data-tiers.html) for more details about storage tiers.

This is usually a starting point. Run tests to determine that the estimated size meets your functional and nonfunctional requirements.

### Use case: 100 qps
Consider the following usecase:
> **Access logs**
> - QPS: 100
> - Retention period: 1 day
> - HOT tier: 1 day
> - replica: 1

> **Application logs**
> - QPS: 100
> - Retention period: 1 day
> - HOT tier: 1 day
> - replica: 1

> **Debug logs**
> - QPS: 4*100 = 400 QPS
> - Retention period:
>   - 1 day, Assumption is debug logs are enabled only for 1 hour in 1 day.
> - HOT tier: 1 day
> - replica: 1

The cluster sizing for this use case.

**Case 1: Only access logs**

> **Total storage**
> - Daily source data = 100 * 60 seconds * 60 minutes * 24 hours * 1.2KB = 10.368GB
> - Storage needed = 10.368 * (1 + 1) * 1.25 * 1 = 26GB for 1 day
> - Total storage = **26GB**

> **Number of data nodes**
> - **Scenario 1**: Jvm memory per Data Node = 8GB
> - Total Data Nodes = ROUNDUP(26 / 8 / 1:30) = 0.10 = **1** data nodes
> - **Scenario 2**: Jvm memory per Data Node = 16GB
> - Total Data Nodes = ROUNDUP(26 / 16 / 1:30) = 0.05 = **1** data nodes
> - **Scenario 3**: Jvm memory per Data Node = 32GB
> - Total Data Nodes = ROUNDUP(26 / 32 / 1:30) = 0.027 = **1** data nodes
> 
> _Note: In all the above scenarios, we can use 1 data node, but we recommend using at least 2 data nodes for replication purposes._

**Case 2: Access logs + Application logs**

> **Total storage**
>   - Access logs:
>     - Daily source data = 100 * 60 seconds * 60 minutes * 24 hours * 1.2KB = 10.368GB
>     - Storage needed = 10.368 * (1 + 1) * 1.25 * 1 = 26GB for 1 day
>   - Application logs:
>     - Daily source data = 100 * 60 seconds * 60 minutes * 24 hours * 1KB = 8.64GB
>     - Storage needed = 8.64 * (1 + 1) * 1.25 * 1 = 21.6GB for 1 day
> 
>   Total storage = 26 + 21.6 = **47.6**

> **Number of data nodes**
> - **Scenario 1**: Jvm memory per Data Node = 8GB
> - Total Data Nodes = ROUNDUP(47.6 / 8 / 1:30) = 0.198 = **1** data nodes
> - **Scenario 2**: Jvm memory per Data Node = 16GB
> - Total Data Nodes = ROUNDUP(47.6 / 16 / 1:30) = 0.099 = **1** data nodes
> - **Scenario 3**: Jvm memory per Data Node = 32GB
> - Total Data Nodes = ROUNDUP(47.6 / 32 / 1:30) = 0.049 = **1** data nodes

> _Note: In all the above scenarios, you can use 1 data node, but TIBCO recommends using at least 2 data nodes for replication purposes._

**Case 3: Access logs + Application logs + Debug logs**
> - **Total storage**
> - Access logs:
>   - Daily source data = 100 * 60 seconds * 60 minutes * 24 hours * 1.2KB = 10.368GB
>   - Storage needed = 10.368 * (1 + 1) * 1.25 * 1 = 26GB for 30 days
> - Application logs:
>   - Daily source data = 100 * 60 seconds * 60 minutes * 24 hours * 1KB = 8.64GB
>   - Storage needed = 8.64 * (1 + 1) * 1.25 * 1 = 21.6GB for 30 days
> - Debug logs:
>   - Daily source data = 400 * 60 seconds * 60 minutes * 1 hour * 1MB = 1440 GB
>   - Storage needed = 1440 * (1 + 1) * 1.25 * 1 day retention = ~3600 GB for 1 hour per day
> - Total storage = 26 + 21.6 + 3600 = **3647.6 GB**

> **Number of data nodes**
> - **Scenario 1**: Jvm memory per Data Node = 8GB
> - Total Data Nodes = ROUNDUP(3647.6 / 8 / 1:30) = **15** data nodes
> - **Scenario 2**: Jvm memory per Data Node = 16GB
> - Total Data Nodes = ROUNDUP(3647.6 / 16 / 1:30) = **8** data nodes
> - **Scenario 3**: Jvm memory per Data Node = 32GB
> - Total Data Nodes = ROUNDUP(3647.6 / 32 / 1:30) = **4** data nodes

Based on the above calculations, you can see that the number of nodes required is inversely proportional to the memory per data node. The higher the memory per data node, the lower the number of nodes required.
By default, an Observability stack such as Opensearch uses 50% of the instance's RAM for the JVM heap, up to a heap size of 32GB. So TIBCO recommends using an instance type with at max 64GB of RAM.


### Suggested Matrix

Considering the above use case, you can create a matrix for different QPS.

#### Without debug logs
| QPS  | Access logs | Application logs | Total Storage | Total Data Nodes |
|:-----|:------------|:-----------------|:--------------|:-----------------|
| 100  | 26 GB       | 21.6 GB          | 47.6 GB       | 2                |
| 200  | 52 GB       | 43.2 GB          | 95.2 GB       | 2                |
| 500  | 130 GB      | 108 GB           | 238 GB        | 2                |
| 1000 | 260 GB      | 216 GB           | 476 GB        | 2                |

#### With debug logs
| QPS  | Access logs | Application logs | Debug logs | Total Storage | Total Data Nodes |
|:-----|:------------|:-----------------|:-----------|:--------------|:-----------------|
| 100  | 26 GB       | 21.6 GB          | 3600 GB    | 3.64 TB       | 4                |
| 200  | 52 GB       | 43.2 GB          | 7200 GB    | 7.3 TB        | 8                |
| 500  | 130 GB      | 108 GB           | 18000 GB   | 18.2 TB       | 19               |
| 1000 | 260 GB      | 216 GB           | 36000 GB   | 36.4 TB       | 38               |


### Choosing instance types and testing
Once you have the number of data nodes, you can choose the instance type. You can use the [Instance types](https://aws.amazon.com/ec2/instance-types/) to choose the instance type.
CPU and memory are the two most important factors to consider when choosing an instance type. The CPU and memory requirements of the instance type you choose should be based on the performance requirements of your use case.
CPU estimation depends on a lot of factors:
- Number of users
- Search performance
- Complex queries
- Number of concurrent searches
- Number of concurrent indexing requests

The cluster is composed of data nodes and cluster manager/master nodes. Although dedicated master nodes don't process search and query requests, their size is highly correlated with the instance size and number of instances, indexes, and shards that they can manage. [AWS documentation](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/managedomains-dedicatedmasternodes.html#dedicatedmasternodes-instance) provides a matrix that recommends a minimum dedicated cluster manager instance type. For small size cluster you can assign master role to data nodes. For large size cluster, we recommend dedicated master nodes.

We suggest you choose the instance type based on the above factors and run tests to determine that the estimated size meets your functional and nonfunctional requirements.

### References
- [Sizing domains](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/sizing-domains.html)
- [Benchmarking and sizing your elasticsearch cluster for logs the use case](https://www.elastic.co/blog/benchmarking-and-sizing-your-elasticsearch-cluster-for-logs-and-metrics)
- [Opensearch sizing](https://docs.aws.amazon.com/prescriptive-guidance/latest/opensearch-service-migration/sizing.html)
- [Instance types](https://aws.amazon.com/ec2/instance-types/)
- [Quantitative cluster sizing](https://www.elastic.co/elasticon/conf/2016/sf/quantitative-cluster-sizing)


