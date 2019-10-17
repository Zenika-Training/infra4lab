FROM alpine:3.10

RUN adduser -D ansible

WORKDIR /work

# Ansible
COPY requirements.txt .
RUN apk add --no-cache openssh python3 py3-jinja2 py3-yaml py3-cryptography py3-urllib3 py3-docutils py3-dateutil \
 && pip3 --no-cache-dir install --requirement requirements.txt
ENV BOTO_USE_ENDPOINT_HEURISTICS=True

# Terraform
ENV TERRAFORM_VERSION=0.12.10
RUN apk add --no-cache ca-certificates \
 && wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
 && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/ \
 && rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip

COPY . .

VOLUME /training
USER ansible
ENTRYPOINT ["ansible-playbook", "--inventory", "localhost", "--inventory", "/training/sessions/current/hosts.aws_ec2.yml", "infra.yml"]
