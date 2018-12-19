# Configure the Amazon AWS Provider
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.region}"
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_eip" "eip_gitlab" {
  instance = "${aws_instance.gitlab-dip.id}"
  vpc      = true
}

resource "aws_eip" "eip_rancher" {
  instance = "${aws_instance.rancherserver.id}"
  vpc      = true
}

resource "aws_subnet" "public-subnet" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.0.0.1/24"
  //availability_zone = "eu-west-1a"

  tags {
    Name = "Public Subnet"
  }
}

# Define the route table
resource "aws_route_table" "web-public-rt" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "Public Subnet RT"
  }
}

resource "aws_route_table_association" "web-public-rt" {
  subnet_id = "${aws_subnet.public-dip-subnet.id}"
  route_table_id = "${aws_route_table.web-public-rt.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_security_group" "default" {
  name        = "default"
  description = "default"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow internal comms in the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


data "template_cloudinit_config" "rancherserver-cloudinit" {
  part {
    content_type = "text/cloud-config"
    content      = "hostname: ${var.prefix}-rancherserver\nmanage_etc_hosts: true"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.userdata_server.rendered}"
  }
}

resource "aws_instance" "gitlab" {
  ami = "ami-00562538339c5031c"
  instance_type   = "${var.server_instancetype}"
  security_groups = [ "${aws_security_group.dipdefault.id}" ]
  subnet_id       = "${aws_subnet.public-dip-subnet.id}"
  key_name        = "${var.ssh_key_name}"

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = 20
  }

  tags {
    Name = "gitlab"
  }
}

resource "aws_route53_record" "gitlab" {
  zone_id = "${var.hosted_zone_id}"
  name = "gitlab"
  type = "A"
  ttl = "300"
  records = ["${aws_eip.eip_gitlab.public_ip}"]
}

resource "aws_route53_record" "rancherserver" {
  zone_id = "${var.hosted_zone_id}"
  name = "rancher"
  type = "A"
  ttl = "300"
  records = ["${aws_eip.eip_rancher.public_ip}"]
}


resource "aws_instance" "rancherserver" {
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "${var.server_instancetype}"
  key_name        = "${var.ssh_key_name}"
  security_groups = [ "${aws_security_group.default.id}" ]
  subnet_id       = "${aws_subnet.public-subnet.id}"
  //iam_instance_profile = "${aws_iam_instance_profile.ec2-profile.name}"
  user_data       = "${data.template_cloudinit_config.rancherserver-cloudinit.rendered}"
  tags {
    Name = "${var.prefix}-rancherserver"
  }
}

data "template_cloudinit_config" "rancheragent-all-cloudinit" {
  count = "${var.count_agent_all_nodes}"

  part {
    content_type = "text/cloud-config"
    content      = "hostname: ${var.prefix}-rancheragent-${count.index}-all\nmanage_etc_hosts: true"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.userdata_agent.rendered}"
  }
}

resource "aws_instance" "rancheragent-all" {
  count           = "${var.count_agent_all_nodes}"
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "${var.agentall_instancetype}"
  key_name        = "${var.ssh_key_name}"
  security_groups = [ "${aws_security_group.default.id}" ]
  //iam_instance_profile = "${aws_iam_instance_profile.ec2-profile.name}"
  subnet_id       = "${aws_subnet.public-subnet.id}"
  user_data       = "${data.template_cloudinit_config.rancheragent-all-cloudinit.*.rendered[count.index]}"

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = 20
  }

  tags {
    Name = "${var.prefix}-rancheragent-${count.index}-all"
  }
}

data "template_cloudinit_config" "rancheragent-etcd-cloudinit" {
  count = "${var.count_agent_etcd_nodes}"

  part {
    content_type = "text/cloud-config"
    content      = "hostname: ${var.prefix}-rancheragent-${count.index}-etcd\nmanage_etc_hosts: true"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.userdata_agent.rendered}"
  }
}

resource "aws_instance" "rancheragent-etcd" {
  count           = "${var.count_agent_etcd_nodes}"
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "${var.etcd_instancetype}"
  key_name        = "${var.ssh_key_name}"
  security_groups = [ "${aws_security_group.dipdefault.id}" ]
  subnet_id       = "${aws_subnet.public-subnet.id}"
  //iam_instance_profile = "${aws_iam_instance_profile.ec2-profile.name}"
  user_data       = "${data.template_cloudinit_config.rancheragent-etcd-cloudinit.*.rendered[count.index]}"
  tags {
    Name = "${var.prefix}-rancheragent-${count.index}-etcd"
  }
}

data "template_cloudinit_config" "rancheragent-controlplane-cloudinit" {
  count = "${var.count_agent_controlplane_nodes}"

  part {
    content_type = "text/cloud-config"
    content      = "hostname: ${var.prefix}-rancheragent-${count.index}-controlplane\nmanage_etc_hosts: true"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.userdata_agent.rendered}"
  }
}

resource "aws_instance" "rancheragent-controlplane" {
  count           = "${var.count_agent_controlplane_nodes}"
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "${var.controlplane_instancetype}"
  key_name        = "${var.ssh_key_name}"
  security_groups = [ "${aws_security_group.default.id}" ]
  subnet_id       = "${aws_subnet.public-subnet.id}"
  //iam_instance_profile = "${aws_iam_instance_profile.ec2-profile.name}"
  user_data     = "${data.template_cloudinit_config.rancheragent-controlplane-cloudinit.*.rendered[count.index]}"
  tags {
    Name = "${var.prefix}-rancheragent-${count.index}-controlplane"
  }
}

data "template_cloudinit_config" "rancheragent-worker-cloudinit" {
  count = "${var.count_agent_worker_nodes}"

  part {
    content_type = "text/cloud-config"
    content      = "hostname: ${var.prefix}-rancheragent-${count.index}-worker\nmanage_etc_hosts: true"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.userdata_agent.rendered}"
  }
}

resource "aws_instance" "rancheragent-worker" {
  count           = "${var.count_agent_worker_nodes}"
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "${var.worker_instancetype}"
  key_name        = "${var.ssh_key_name}"
  security_groups = [ "${aws_security_group.default.id}" ]
  //iam_instance_profile = "${aws_iam_instance_profile.ec2-profile.name}"
  subnet_id       = "${aws_subnet.public-subnet.id}"
  user_data       = "${data.template_cloudinit_config.rancheragent-worker-cloudinit.*.rendered[count.index]}"
  tags {
    Name = "${var.prefix}-rancheragent-${count.index}-worker"
  }
}

data "template_file" "userdata_server" {
  template = "${file("files/userdata_server")}"

  vars {
    admin_password        = "${var.admin_password}"
    cluster_name          = "${var.cluster_name}"
    docker_version_server = "${var.docker_version_server}"
    rancher_version       = "${var.rancher_version}"
  }
}

data "template_file" "userdata_agent" {
  template = "${file("files/userdata_agent")}"

  vars {
    admin_password       = "${var.admin_password}"
    cluster_name         = "${var.cluster_name}"
    docker_version_agent = "${var.docker_version_agent}"
    rancher_version      = "${var.rancher_version}"
    server_address       = "${aws_instance.rancherserver.public_ip}"
  }
}

/*
resource "aws_iam_role" "ec2-iam-role" {
  name               = "ec2-iam-role"
  assume_role_policy = "${file("files/ec2-policy.json")}"
}

resource "aws_iam_instance_profile" "ec2-profile" {
  name  = "ec2-profile"
  role = "${aws_iam_role.ec2-iam-role.name}"
}
*/
