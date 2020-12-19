# macOS based EC2 (Infra-as-Code)

## Prerequisites

A macOS based EC2 relies on a AWS dedicated host

- In AWS ServicesQuota, check the quota for Dedicated Hosts (at least 1 mac1.metal)
- Python 3.x (for Ansible)
- install Terraform : https://www.terraform.io/
- install Ansible: https://www.ansible.com/

## Key pair

The key pair will be used to access the EC2 instance via SSH

```script
ssh-keygen -P "" -t rsa -b 4096 -m pem -f key -C ""
```

It will generate a _key_ file (private key) and a _key.pub_ file (public key) in the root folder

## Terraform

**(Within the terraform folder)**

### Create AWS assets

Initialize Terraform providers

```script
terraform init
```

Deploy Terraform resources

```script
terraform apply -var region=us-west-1 -var az=eu-west-1a
```

The result will be a running macOS based EC2 instance, within a VPC and accesible via SSH (port 22).

:information_source: Wait until the instance status checks are fine (may take several minutes)

Test SSH connection

```script
ssh -i ../key ec2-user@<Instance-Public-HostName>>
```

### Remove AWS assets (optional)

In case you want to remove all AWS assets

```script
terraform destroy
```

:warning: As the EC2 instance stays in _terminated_ state for few hours, you cannot remove the Dedicated Host until the EC2 instance is gone.
Therefore, the first time you run the above command, it will fail, but all AWS assets are removed **except the Dedicated Host**.
So, execute the command a second time when the EC2 instance disappears.

## Ansible

**(Within the ansible folder)**

### Prerequisites

We are going to use the _amazon.aws.aws_ec2_ Ansible plugin, in order to build a dynamic Ansible inventory based on tag values (see _aws_ec2.yaml_ file)

```script
pip install boto3 botocore
```

### Test

Run the following command, and it should return your EC2 instance

```script
ansible-inventory --list
```

```script
ansible all --private-key ../key --user ec2-user --module-name ping
```

### Connect to EC2 with VNC

Execute Ansible playbook in order to set a password for user ec2-user and enable VNC

```script
ansible-playbook --private-key ../key --user ec2-user --extra-vars "password=<password for ec2-user>" configure.yaml
```

As VNC data is not encrypted, we are going to use VNC through an SSH tunnel

```script
ssh -L 5900:localhost:5900 -i ../key ec2-user@<Instance-Public-HostName>
```

Starting from now, with a VNC client, the EC2 instance can be reached from vnc://localhost:5900

:warning: The EC2 instance may be configured with an english keyboard layout

## Resources

- https://marcincuber.medium.com/aws-mac-instances-with-terraform-701b8b292e9e
- https://howto.lintel.in/setting-ansible-aws-dynamic-inventory-ec2/
