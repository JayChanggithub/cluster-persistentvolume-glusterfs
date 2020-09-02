Cluster-PersistentVolume-Glusterfs
============================

## Suitable Project

  - [x] None


---

## Version
`Rev: 1.0.0`


---

## Description
   
  - Glusterfs is free and open source software for scalable network filesystem, used it be our kubernetes cluster persistent solutions.

---

## Usage


  - Add other nodes to cluster

    ```bash
    $ gluster peer probe <node>
    ```

  - Display the cluster status

    ```bash
    $ gluster peer status
    ```

  - Display the volumes information

    ```bash
    $ gluster volume info
    ```

  - Create new brick be share replicas volumes

    ```bash
    $ gluster volume create <volume name> replica 3 <node1>:<folder> <node2>:<folder> <node3>:<folder> force
    ```

  - Enabled the volumes to use

    ```bash
    $ gluster volume start <volume name>
    ```

---

## Associates

  - **Developer**
    - Chang.Jay

---

## Contact
##### Author: Jay.Chang
##### Email: cqe5914678@gmail.com
