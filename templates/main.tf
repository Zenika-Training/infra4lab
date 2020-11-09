# Configure the AWS Provider
provider "aws" {
  region = "{{ aws_region }}"
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "availability_zones" {
  state = "available"
}

data "aws_ami" "ami" {
  most_recent = true
  owners = ["{{ current_os.aws_ami_owner }}"]
  name_regex = "{{ current_os.aws_ami_name_regex }}"

  {% for name, value in (current_os.aws_ami_filters | default({})).items() %}
  filter {
    name   = "{{ name }}"
    values = ["{{ value }}"]
  }
  {% endfor %}
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.56.0"

  name = "vpc"
  cidr = "10.0.0.0/16"

  azs            = data.aws_availability_zones.availability_zones.names
  public_subnets = [for az in data.aws_availability_zones.availability_zones.zone_ids : cidrsubnet("10.0.0.0/16", 8, 101 + index(data.aws_availability_zones.availability_zones.zone_ids, az))]

  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name   = "{{ session_name }}"
    Caller = data.aws_caller_identity.current.arn
  }
}

{% set cidr_blocks = (['0.0.0.0/0'] if open_worldwide | default(False) else (current_session_authorized_ips | map('regex_replace', '$', '/32') | list)) | to_json %}
resource "aws_security_group" "default_sg" {
  name        = "{{ session_name }}"
  description = "Allow inbound traffic"
  vpc_id      = module.vpc.vpc_id

  {% for port in base_open_ports | union(open_ports | default([])) %}
  ingress {
    from_port   = {% if port is mapping %}{{ port.from }}{% else %}{{ port }}{% endif %}
    to_port     = {% if port is mapping %}{{ port.to }}{% else %}{{ port }}{% endif %}
    protocol    = "tcp"
    cidr_blocks = {{ cidr_blocks }}
  }
  {% endfor %}
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = {{ cidr_blocks }}
  }
  tags = {
    Name   = "{{ session_name }}"
    Caller = data.aws_caller_identity.current.arn
  }
}

{% for user in users %}
resource "tls_private_key" "{{ user }}_generated_keypair" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "local_file" "{{ user }}_private_key" {
  filename = "${path.module}/../users/{{ user }}/{{ user }}.pem"
  content  = tls_private_key.{{ user }}_generated_keypair.private_key_pem

  provisioner "local-exec" {
    command = "chmod 400 ${path.module}/../users/{{ user }}/{{ user }}.pem"
  }
}

resource "aws_key_pair" "{{ user }}_aws_keypair" {
  key_name   = "{{ user }}-{{ session_name }}"
  public_key = tls_private_key.{{ user }}_generated_keypair.public_key_openssh
}

{% for instance in aws_instances %}
resource "aws_instance" "{{ user }}_{{ instance.name }}" {
  key_name               = aws_key_pair.{{ user }}_aws_keypair.key_name
  ami                    = data.aws_ami.ami.id
  instance_type          = "{{ instance.type }}"
  vpc_security_group_ids = [aws_security_group.default_sg.id, module.vpc.default_security_group_id]
  subnet_id              = module.vpc.public_subnets[{{ loop.index0 }} % length(module.vpc.public_subnets)]

  tags = {
    Name     = "{{ session_name }}-{{ user }}-{{ instance.name }}"
    Caller   = data.aws_caller_identity.current.arn
    Hostname = "{{ instance.name }}"
    Training = "{{ training_name }}"
    Session  = "{{ session_name }}"
    Trainee  = "{{ user }}"
  }

  provisioner "file" {
    source      = "../users/{{ user }}/{{ user }}.pem"
    destination = "/home/{{ current_os.user }}/.ssh/id_rsa"

    connection {
      user        = "{{ current_os.user }}"
      private_key = tls_private_key.{{ user }}_generated_keypair.private_key_pem
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /home/{{ current_os.user }}/.ssh/id_rsa",
      "sudo hostnamectl set-hostname --static {{ instance.name }}.{{ session_name }}.local",
    ]

    connection {
      user        = "{{ current_os.user }}"
      private_key = tls_private_key.{{ user }}_generated_keypair.private_key_pem
      host        = self.public_ip
    }
  }
}
{% endfor %}

{% endfor %}
