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

resource "aws_security_group" "default_sg" {
  name        = "default-sg-{{ session_name }}"
  description = "Allow inbound traffic from any IP"

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
  ingress {
    from_port   = 8000
    to_port     = 8999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
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
