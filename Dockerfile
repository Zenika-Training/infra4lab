FROM alpine:3.13

RUN adduser -D ansible

WORKDIR /work

# PuTTY
RUN apk add --no-cache putty

# Ansible
COPY requirements.txt .
RUN apk add --no-cache openssh python3 py3-pip py3-jinja2 py3-yaml py3-cryptography py3-urllib3 py3-docutils py3-dateutil py3-jmespath rsync \
 && pip3 --no-cache-dir install --requirement requirements.txt \
 && ln -s python3 /usr/bin/python
ENV BOTO_USE_ENDPOINT_HEURISTICS=True

# Terraform
ENV TERRAFORM_VERSION=1.0.0
RUN apk add --no-cache git ca-certificates \
 && wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
 && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/ \
 && rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip

COPY . .

VOLUME /training
USER ansible
ENTRYPOINT ["ansible-playbook", "--inventory", "localhost", "--inventory", "/training/sessions/current/hosts.aws_ec2.yml", "infra.yml"]
