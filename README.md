## Rancher with Gitlab AWS

- Based on rancher/quickstart aws

### How to use
- Set variable values in `terraform.tfvars`
- Route53 records depend on an existing Hosted Zone  
- Run `terraform init`
- Run `terraform plan`
- Run `terraform apply`

### How to Remove
To remove the VM's that have been deployed run `terraform destroy --force`

### Optional adding nodes per role
- Start `count_agent_all_nodes` amount of AWS EC2 Instances and add them to the custom cluster with all role
- Start `count_agent_etcd_nodes` amount of AWS EC2 Instances and add them to the custom cluster with etcd role
- Start `count_agent_controlplane_nodes` amount of AWS EC2 Instances and add them to the custom cluster with controlplane role
- Start `count_agent_worker_nodes` amount of AWS EC2 Instances and add them to the custom cluster with worker role
