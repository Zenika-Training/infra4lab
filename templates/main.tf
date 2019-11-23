# Configure the AWS Provider
provider "aws" {
  region = "{{ aws_region }}"
  allowed_account_ids = ["{{ aws_account_id }}"]
}

data "aws_ami" "centos" {
  most_recent = true
  owners = ["679593333241"] # CentOS
  name_regex = "^CentOS Linux 7 .*"

  filter {
    name   = "name"
    values = ["CentOS Linux 7 *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

}

{% set cidr_blocks = current_session_authorized_ips | map('regex_replace', '$', '/32') | list | to_json %}
resource "aws_security_group" "default_sg" {
  name        = "default-sg-{{ session_name }}"
  description = "Allow inbound traffic from any IP"

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
    Name = "Default {{ session_name }}"
  }
}

{% for user in users %}
resource "tls_private_key" "{{ user }}_generated_keypair" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "local_file" "{{ user }}_private_key" {
  filename = "${path.module}/../users/{{ user }}/{{ user }}.pem"
  content  = "${tls_private_key.{{ user }}_generated_keypair.private_key_pem}"

  provisioner "local-exec" {
    command = "chmod 400 ${path.module}/../users/{{ user }}/{{ user }}.pem"
  }
}

resource "aws_key_pair" "{{ user }}_aws_keypair" {
  key_name   = "{{ user }}-{{ session_name }}"
  public_key = "${tls_private_key.{{ user }}_generated_keypair.public_key_openssh}"
}

{% for instance in aws_instances %}
resource "aws_instance" "{{ user }}_{{ instance.name }}" {
  key_name        = "${aws_key_pair.{{ user }}_aws_keypair.key_name}"
  ami             = "${data.aws_ami.centos.id}"
  instance_type   = "{{ instance.type }}"
  security_groups = ["${aws_security_group.default_sg.name}", "default"]

  tags = {
    Name     = "{{ session_name }}-{{ user }}-{{ instance.name }}"
    Hostname = "{{ instance.name }}"
    Training = "{{ training_name }}"
    Session  = "{{ session_name }}"
    Trainee  = "{{ user }}"
  }

  provisioner "file" {
    source      = "../users/{{ user }}/{{ user }}.pem"
    destination = "/home/centos/.ssh/id_rsa"

    connection {
      user        = "centos"
      private_key = "${tls_private_key.{{ user }}_generated_keypair.private_key_pem}"
      host        = "${self.public_ip}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /home/centos/.ssh/id_rsa",
      "sudo hostnamectl set-hostname --static {{ instance.name }}.{{ session_name }}.local",
    ]

    connection {
      user        = "centos"
      private_key = "${tls_private_key.{{ user }}_generated_keypair.private_key_pem}"
      host        = "${self.public_ip}"
    }
  }
}
{% endfor %}

{% endfor %}
