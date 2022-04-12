# Glusterfs Setup

This repository has Terraform code and Ansible playbook to create required instances on GCP Cloud and setup Glusterfs on the nodes automatically.

The terraform code will create instance groups as well for the GlusterFS instances, So that the LB can be created later to use as source mount point.

If you have created the instances on on-premise or other cloud, still the ansible playbook helps on setting up Glusterfs.

Also, it has ansible playbook for Gluster Geo-Replication Setup.

### Terraform command
If you have GCP account and want to create GlusterFS on GCP Cloud, you can use the terraform automation.

Pre-requisites:
1. terraform
2. ansible-playbook
3. GCP Project

#### Configuration Steps before Execute

* Change the network and subnet in the terraform module - [network](Terraform/modules/gcp_vm_instance/main.tf#L15)


* Create tfvars file like [gfs-poc.tfvars](Terraform/gfs-poc.tfvars)

#### Execute Command
```shell
terraform apply -var 'project=<gcp-project-name>' -var 'credentials=<gcp-authentication.json>' -var 'ansible_ssh_user=<ansible_ssh_user>' -var-file=<variable-file>
```

### Ansible-playbook for GlusterFS Setup

If you have VM instances for GlusterFS Setup, you can use the Ansible playbook for GlusterFS Setup.

* Create inventory file with your hosts like [gfs-poc.ini](Ansible/inventory/gfs-poc.ini)

#### Execute Command

```shell
cd Ansible
ansible-playbook -i <inventory-file> glusterfs_setup.yml -e "ansible_ssh_user=<ansible_ssh_user>"
```

# GlusterFS Geo-Replication Setup
If you want setup GlusterFS for DR region backup, you can follow the below steps,

* Create inventory file with master and slave nodes like [gfs-geo.ini](Ansible/inventory/gfs-geo.ini)


* Generate ssh keys at "Ansible/roles/glusterfs-geo/files" path using `ssh-keygen` command. It will be used in GlusterFS Geo-Replication Setup.

#### Execute command
```shell
ansible-playbook -i <inventory-file> glusterfs-geo-replication.yml -e "ansible_ssh_user=<ansible_ssh_user>"
```

# GlusterFS-Exporter Prometheus Monitoring Setup

https://github.com/gluster/gluster-prometheus#prometheus-exporter-for-gluster-metrics

1) Install goang and it packages
```shell
yum install golang git
```

2) Define GOPATH and install gluster-exporter
```shell
export GOPATH=/opt/go
export PATH=$PATH:$GOPATH/bin
mkdir -p $GOPATH/bin
 
mkdir -p $GOPATH/src/github.com/gluster
cd $GOPATH/src/github.com/gluster
git clone https://github.com/gluster/gluster-prometheus.git
cd gluster-prometheus
 
# Install the required dependancies.
# Hint: assumes that GOPATH and PATH are already configured.
./scripts/install-reqs.sh
 
PREFIX=/usr make
PREFIX=/usr make install
```

3) Once the install is completed successfully, update "gluster-cluster-id" with cluster name on `/etc/gluster-exporter/gluster-exporter.toml` file.
   cluster name is just a custom name to differentiate metrics from other cluster metrics in the grafana dashboard.

4) Start and enable gluster-exporter service
```shell
# systemctl enable gluster-exporter
# systemctl start gluster-exporter
```

5) Verify metrics at URL http://<ip_address>:9713/metrics
