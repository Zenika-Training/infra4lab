# Infra4lab context

export INSTANCE_ID={{ instance_id }}
export PUBLIC_DNS={{ public_dns_name }}
export PUBLIC_IP={{ public_ip_address }}
export PRIVATE_DNS={{ private_dns_name }}
export PRIVATE_IP={{ private_ip_address }}
export HOSTNAME={{ hostname }}
export TRAINEE="{{ trainee }}"
export SESSION_CLIENT="{{ session_client }}"
export SESSION_NAME="{{ session_name }}"

{% for host in groups[trainee] %}
{% set normalized_host = hostvars[host].hostname | upper | regex_replace('[^\w]', '_') %}
export {{ normalized_host }}_PUBLIC_DNS={{ hostvars[host].public_dns_name }}
export {{ normalized_host }}_PUBLIC_IP={{ hostvars[host].public_ip_address }}
export {{ normalized_host }}_PRIVATE_DNS={{ hostvars[host].private_dns_name }}
export {{ normalized_host }}_PRIVATE_IP={{ hostvars[host].private_ip_address }}

{% endfor %}
