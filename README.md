# Glusterfs Setup

This repository has Terraform code and Ansible playbook to create required instances on GCP Cloud and setup Glusterfs on the nodes automatically.

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
