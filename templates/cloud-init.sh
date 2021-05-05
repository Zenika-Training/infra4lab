#!/bin/bash

{% if os | default() in ['ubuntu', 'ubuntu_desktop'] %}
apt-get install --assume-yes ansible git
{% else %}{# Default to centos #}
yum install --assumeyes epel-release
yum install --assumeyes ansible git
{% endif %}

INVENTORY=$(mktemp --suffix .inventory)
cat <<EOF >${INVENTORY}
[vms]
localhost ansible_connection=local
[{{ instance }}]
localhost
EOF

TRAINING_FOLDER=$(mktemp --directory --suffix .training)
cat <<EOF >${TRAINING_FOLDER}/{{ training_vars_file | replace(training_folder + '/', '') }}
{{ lookup('file', training_vars_file) }}
EOF

EXTRA_VARS=$(mktemp --suffix .vars.yml)
cat <<EOF >${EXTRA_VARS}
training_folder: ${TRAINING_FOLDER}
strigo: true
EOF

{# Sadly looks like this user-data is not OK on Strigo (even if file size is below the ~16384 bytes size limit)
{% for workspace in roles | default([]) | selectattr('name', 'equalto', 'workspaces') %}
{% if instance in workspace.target | default([]) %}
cat <<EOF | base64 --decode | tar --extract --gzip --file - --directory /home/centos
{{ lookup('pipe', 'tar --create --gzip --file - ' + (workspace.vars | default({})).workspaces_folder | default('/workspaces') + ' | base64') }}
EOF
{% endif %}
{% endfor %}
#}

ansible-pull --inventory ${INVENTORY} --url https://github.com/Zenika/infra4lab.git setup.yml --extra-vars @${EXTRA_VARS}

{% if instance in (roles | default([]) | selectattr('name', 'equalto', 'docker') | first).target | default([]) %}
reboot
{% endif %}
