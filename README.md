# Kubernetes Cluster Setups

This project is aiming to ease kubernetes (k8s) cluster creation on different platform (cloud and on-premise providers) for learning purposes.

In this repo, you'll find code for:

* Setting up k8s cluster using raw Shell scripts or Ansible playbooks
* Setting up k8s cluster using terraform
* Setting up k8s cluster using vagrant

## Contents

* Requirements
* Setting up k8s using Shell scripts or Ansible
* Setting up k8s using Terraform
* Setting up k8s using Vagrant
* Checking your cluster setup

## Requirements

- For Shell scripts

No requirements need to run shell scripts.

- For Raw Ansible playbooks

Before you begin, you need to install Ansible on your controller node.

- For Terraform

Before you begin, you need to install Ansible and Terraform on your controller node.

- For Vagrant

Before you begin, you need to install Vagrant on your computer

:bulb: You'll also need to clone this repo

```shell
git clone https://github.com/jaquiteme/k8s-cluster-setup.git
```

## Setting up k8s using Shell scripts or Ansible


- **Shell**

To setup your k8s cluster using shell scripts, you'll need: 

1. Give execution permissions to scripts files.

```shell
chmod +x k8s-cluster-setup/provisioning/scripts/*.sh
```

2. Run ``k8s-cluster-setup/provisioning/scripts/setup-k8s.sh`` script on all your nodes

```shell
./k8s-cluster-setup/provisioning/scripts/setup-k8s.sh
```

3. Run ``k8s-cluster-setup/provisioning/scripts/init-cluster.sh`` script on your master node

```shell
./k8s-cluster-setup/provisioning/scripts/init-cluster.sh
```

4. Run cluster join command that will be output at the end of ``k8s-cluster-setup/provisioning/scripts/init-cluster.sh`` script

```shell
[WORKERS JOIN COMMAND] => copy and paste the command below on your worker nodes
kubeadm join API_SERVER_ADDR:6443 --token p... --discovery-token-ca-cert-hash sha256:0a..
```

- **Ansible**

To setup your k8s cluster using Ansible, you'll need: 

1. Run ``k8s-cluster-setup/provisioning/playbooks/k8s-master-setup.yml`` playbook on your master nodes

```shell
 ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
      -u YOUR_USER_NAME -i "YOUR_MASTER_NODE_IP," \
      --private-key "YOUR_USER_PRIVATE_KEY" \
      -e "pub_key=YOUR_USER_PUBLIC_KEY" \
      ../../provisioning/playbooks/k8s-master-setup.yml
```

2. Run ``k8s-cluster-setup/provisioning/playbooks/k8s-worker-setup.yml`` playbook on your worker nodes

```shell
 ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
      -u YOUR_USER_NAME -i "YOUR_MASTER_NODE_IP," \
      --private-key "YOUR_USER_PRIVATE_KEY" \
      -e "pub_key=YOUR_USER_PUBLIC_KEY" \
      ../../provisioning/playbooks/k8s-worker-setup.yml
```

:bulb: You can also use these playbooks with your customized ansible.cfg and inventory.

- **Terraform**

To setup your k8s cluster using Terraform, you'll need: 

* On AWS cloud provider

1. Edit ``credentials`` file and add your AWS access key id and secret access key

```shell
aws_access_key_id=YOUR_AWS_ACCESS_KEY_ID
aws_secret_access_key=YOUR_AWS_SECRET_ACCESS_KEY
```

2. Run terraform init

```shell
cd k8s-cluster-setup/terraform/aws && terraform init
```

3. Run terraform apply

```shell
cd k8s-cluster-setup/terraform/aws && terraform apply
```

- **Vagrant**

To setup your k8s cluster using Vagrant, you'll need to run the following command.

```shell
cd k8s-cluster-setup/vagrant
vagrant up
```

:caution: The vagrant setup was tested only on a Windows machine.

## Checking your cluster setup
[TODO]