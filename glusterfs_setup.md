# Manual Steps
This Documentation helps to set up GlusterFS cluster with HA and Geo-Replication through manual Executions.

## GlusterFS Setup
#### Follow steps on all glustefs nodes
1) Install the latest glusterfs package on your all instances
   
        # yum install -y centos-release-gluster9
        # yum install -y glusterfs-server

2) Disable selinux

        # vi /etc/selinux/config
        update as "SELINUX=disabled"

        # /sbin/setenforce 0

3) Stop firewall service and start the glusterd service

        # systemctl stop firewalld
        # systemctl disable firewalld

        # systemctl enable glusterd.service
        # systemctl start glusterd.service

4) Set variables which will be used in multiple places
   
        # brick_name=`hostname -s`_brick
        # disk_path=/dev/sdb
        # data_path=/data/glusterfs
        # gfs_volume="vol1"

5) Create Physical volume and volume group
   
        # pvcreate $disk_path

        # vgcreate vg_gfs $disk_path

6) Create LVM and format it with XFS
   
        # lvcreate -n $brick_name vg_gfs -l+100%FREE

        # mkfs.xfs /dev/vg_gfs/$brick_name

7) Create Self mount on the node

        # mkdir -p ${data_path}
        # mount /dev/vg_gfs/$brick_name ${data_path}
        # echo "/dev/vg_gfs/$brick_name ${data_path} xfs defaults 0 0" >> /etc/fstab

8) Create gluster volume directory

        # mkdir -p ${data_path}/${gfs_volume}

#### Run the below steps on any one of the glusterfs node
9) Establish peer probe from the current node to all other nodes one by one

        # gluster peer probe <node2_ipaddr>
        # gluster peer probe <node3_ipaddr>
        # gluster peer probe <node4_ipaddr>

10) Verify the gluster peer and pool

        # gluster peer status
        # gluster pool list

11) Create gluster volume and start it

        # gluster volume create ${gfs_volume} replica 2 <node1_ipaddr>:${data_path}/${gfs_volume} <node2_ipaddr>:${data_path}/${gfs_volume} <node3_ipaddr>:/${data_path}/${gfs_volume} <node4_ipaddr>:${data_path}/${gfs_volume} force

        # gluster volume start ${gfs_volume}
        # gluster volume info ${gfs_volume}

#### Mount volume on every glusterfs nodes

    # mkdir -p /mnt/glusterfs
    # mount -t glusterfs 127.0.0.1:/${gfs_volume}  /mnt/glusterfs
    # echo "127.0.0.1:/${gfs_volume}  /mnt/glusterfs glusterfs defaults,_netdev 0 0" >> /etc/fstab
    # mount -a



## Gluster Geo-Replication Setup
1) Install gluster-geo-replication package on all primary and secondary nodes

        # yum install -y glusterfs-geo-replication

2) Generate the ssh-keygen and keep private and public keys on Primary's first/main and Secondary's first/main nodes in the root user

        # ssh-keygen

3) Add the public key as authorized_keys on all Primary and Second nodes in the root user

        # vi /root/.ssh/authorized_keys

4) Enable Root Login on your /etc/ssh/sshd_config file

        # vi /etc/ssh/sshd_config
          PermitRootLogin yes

5) Set this volume config on the Secondary main node

        # gluster volume set <gfs_voulme> performance.quick-read off

6) Enable shared storage for volume, Run this command on one of the primary and secondary nodes

        # gluster volume set all cluster.enable-shared-storage enable

7) Create a common pem pub file, run the following command on one of the primary and secondary nodes

        # gluster system:: execute gsec_create

#### Run the below commands on the Primary main(one of the) node
8) push-pem is needed to to setup the necessary pem-file on the secondary nodes

        # gluster volume geo-replication <gfs_voulme> <secondary_main_IPAddr>::<gfs_volume> create push-pem force

9) Update the configs for geo-replication

        # gluster volume geo-replication <gfs_voulme> <secondary_main_IPAddr>::<gfs_volume> config use_meta_volume true
        # gluster volume geo-replication <gfs_voulme> <secondary_main_IPAddr>::<gfs_volume> config sync-jobs 8

10) Start the geo-replication and verify the status

        # gluster volume geo-replication <gfs_voulme> <secondary_main_IPAddr>::<gfs_volume> start

        # gluster volume geo-replication <gfs_voulme> <secondary_main_IPAddr>::<gfs_volume> status
        # gluster volume geo-replication <gfs_voulme> <secondary_main_IPAddr>::<gfs_volume> status detail

        # gluster volume geo-replication <gfs_voulme> <secondary_main_IPAddr>::<gfs_volume> config log-file



### DR FailOver
Due to any Disaster if you want to switch applications to Secondary GlusterFS, follow the below steps,

1) Disable read-only on the Original Secondary cluster volume

        # gluster volume set <gfs_voulme> features.read-only off

2) Promote the original secondary node to act as new Primary

        # gluster volume set <gfs_voulme> geo-replication.indexing on
        # gluster volume set <gfs_voulme> changelog on

Now your Secondary is ready for applications to write.



#### Replicating data to Original(previous) Primary
3) If the Original  Primary is online, Stop synchronizing to the Original Secondary, Run on the Original Primary node

        # gluster volume geo-replication <gfs_voulme> <secondary_main_IPAddr>::<gfs_volume> delete
        # gluster volume set <gfs_voulme> features.read-only on
        # gluster volume set <gfs_voulme> geo-replication.indexing off
        # gluster volume set <gfs_voulme> changelog off

4) Push pem from the current Primary to Orginal Primary

        # gluster volume geo-replication <gfs_voulme> <Original_Primary_main_IPAddr>::<gfs_volume> create push-pem force

5) Set config special-syn-mode and Disable the gfid-conflict-resolution

        # gluster volume geo-replication <gfs_voulme> <Original_Primary_main_IPAddr>::<gfs_volume> config special-sync-mode recover
        # gluster volume geo-replication <gfs_voulme> <Original_Primary_main_IPAddr>::<gfs_volume> config gfid-conflict-resolution false

6) Start the geo-replication from current Primary to Original Primary

        # gluster volume geo-replication <gfs_voulme> <Original_Primary_main_IPAddr>::<gfs_volume> start
        # gluster volume geo-replication <gfs_voulme> <Original_Primary_main_IPAddr>::<gfs_volume> status



### DR FallBack
In case if you want to switch back to the Original Primary, please follow the below steps.

1) Stop the I/O operations on the current Primary(Original Secondary) and set the checkpoint

        # gluster volume geo-replication <gfs_voulme> <Original_Primary_main_IPAddr>::<gfs_volume> config checkpoint now

2) Checkpoint completion ensures that the data from the original secondary is restored back to the original primary.

        # gluster volume geo-replication <gfs_voulme> <Original_Primary_main_IPAddr>::<gfs_volume> status detail

3) After the checkpoint is complete, stop the current geo-replication session between the original secondary and original primary

        # gluster volume geo-replication <gfs_voulme> <Original_Primary_main_IPAddr>::<gfs_volume> delete
        # gluster volume set <gfs_voulme> features.read-only on
        # gluster volume set <gfs_voulme> geo-replication.indexing off
        # gluster volume set <gfs_voulme> changelog off

4) Disable read-only on the Original Primary cluster volume

        # gluster volume set <gfs_voulme> features.read-only off

5) Promote the original primary node to act as Primary

        # gluster volume set <gfs_voulme> geo-replication.indexing on

        # gluster volume set <gfs_voulme> changelog on

6) Start the geo replication on Original Primary node

        # gluster volume geo-replication <gfs_voulme> <secondary_main_IPAddr>::<gfs_volume> start

#### Troubleshooting
If the geo-replication fails, worst case scenario, delete session and re-create it.

Re-create Geo Session

    # gluster volume geo-replication <gfs_voulme> <secondary_main_IPAddr>::<gfs_volume> delete reset-sync-time
    # gluster volume reset <gfs_voulme> geo-replication.ignore-pid-check force
    # gluster volume reset <gfs_voulme> geo-replication.indexing force
    # gluster volume reset <gfs_voulme> changelog.changelog force
    # gluster volume reset <gfs_voulme> changelog.capture-del-path force
    # rm -rf <data_path>/<gfs_volume>/.glusterfs/changelogs/*
    # gluster volume geo-replication <gfs_voulme> <secondary_main_IPAddr>::<gfs_volume> create push-pem force
    # gluster volume geo-replication <gfs_voulme> <secondary_main_IPAddr>::<gfs_volume> start


## GlusterFS version upgrade
We have to follow the rolling upgrade on GlusterFS nodes which means will take one node out from the gluster cluster, upgrade and add it back.

Just check the version upgrade compatibility from your current version to the new version before you run.

https://docs.gluster.org/en/latest/Upgrade-Guide/upgrade-to-10/

1) Stop the gusterd service

        # systemctl stop glusterd
        # killall glusterfs glusterfsd

        # ps -ef | grep gluster

2) Install upgrade version on the node

        # yum install centos-release-gluster10
        # yum install glusterfs-server

3) Verify the gluster version

        # gluster --version

4) Reload system daemon

        # systemctl daemon-reload

5) Start the glusterd service

        # systemctl start glusterd
        # systemctl status glusterd

6) Mount fstab entries

        # mount -a

7) Check peer status

        # gluster peer status

8) Heal volume and verify it

        # for i in `gluster volume list`; do gluster volume heal $i; done

        # gluster volume heal <gfs_volume> info

        # gluster volume status


## Increase Gluster Volume Size
If your volume size reaches more than 90% usage, you can increase the volume size online.

1) Increase the secondary disk size on all the nodes.

2) Run these commands on all nodes,

### Re-size volume
    # partprobe
    # brick_name=`hostname -s`_brick
    # pvresize /dev/sdb
    # lvextend -l +100%FREE /dev/vg_gfs/${brick_name}
    # xfs_growfs /dev/vg_gfs/${brick_name}

The gluster volume size will be increased now, you can verify it by the df command



## Reference
1) https://docs.gluster.org/en/latest/Administrator-Guide/Geo-Replication/

2) https://access.redhat.com/documentation/en-us/red_hat_gluster_storage/3/html/administration_guide/sect-preparing_to_deploy_geo-replication#Geo-replication_Deployment_Overview

3) https://access.redhat.com/documentation/en-us/red_hat_gluster_storage/3.1/html/administration_guide/sect-disaster_recovery
