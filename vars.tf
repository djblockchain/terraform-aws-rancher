variable "aws_access_key" {
  default     = "xxx"
  description = "Amazon AWS Access Key"
}

variable "aws_secret_key" {
  default     = "xxx"
  description = "Amazon AWS Secret Key"
}

variable "prefix" {
  default     = "yourname"
  description = "Cluster Prefix - All resources created by Terraform have this prefix prepended to them"
}

variable "rancher_version" {
  default     = "latest"
  description = "Rancher Server Version"
}

variable "count_agent_all_nodes" {
  default     = "1"
  description = "Number of Agent All Designation Nodes"
}

variable "count_agent_etcd_nodes" {
  default     = "0"
  description = "Number of ETCD Nodes"
}

variable "count_agent_controlplane_nodes" {
  default     = "0"
  description = "Number of K8s Control Plane Nodes"
}

variable "count_agent_worker_nodes" {
  default     = "0"
  description = "Number of Worker Nodes"
}

variable "admin_password" {
  default     = "admin"
  description = "Password to set for the admin account in Rancher"
}

variable "cluster_name" {
  default     = "quickstart"
  description = "Kubernetes Cluster Name"
}

variable "region" {
  default     = "us-west-2"
  description = "Amazon AWS Region for deployment"
}

variable "server_instancetype" {
  default     = "t3.medium"
  description = "Amazon AWS Instance Type"
}

variable "agentall_instancetype" {
  default     = "t3.medium"
  description = "Amazon AWS Instance Type"
}

variable "worker_instancetype" {
  default     = "t3.medium"
  description = "Amazon AWS Instance Type"
}

variable "controlplane_instancetype" {
  default     = "t3.medium"
  description = "Amazon AWS Instance Type"
}

variable "etcd_instancetype" {
  default     = "t3.medium"
  description = "Amazon AWS Instance Type"
}

variable "docker_version_server" {
  default     = "17.03"
  description = "Docker Version to run on Rancher Server"
}

variable "docker_version_agent" {
  default     = "17.03"
  description = "Docker Version to run on Kubernetes Nodes"
}

variable "ssh_key_name" {
  default     = ""
  description = "Amazon AWS Key Pair Name"
}

variable "hosted_zone_id" {
  default     = ""
  description = "Amazon AWS Route53 Hosted Zone Id"
}
