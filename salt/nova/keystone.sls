{% set nova_serv = ['nova-api','nova-cert', 'nova-conductor', 'nova-consoleauth','nova-novncproxy', 'nova-scheduler'] %}
{% set nova_endpoint = 'http://' + salt['pillar.get']('nova:host', salt['pillar.get']('openstack:controller', grains['fqdn_ip4'][0])) + ':8774/v2/%(tenant_id)s' %}
{% set ec2_endpoint = 'http://' + salt['pillar.get']('nova:host', salt['pillar.get']('openstack:controller', grains['fqdn_ip4'][0])) + ':8773/services/Cloud' %}
{% set region = salt['pillar.get']('nova:region', salt['pillar.get']('openstack:region', 'regionOne')) %}

nova-tenant:
  keystone.tenant_present:
    - name: {{ salt['pillar.get']('nova:service:tenant', 'service') }}
    - description: "OpenStack Service"

nova-user:
  keystone.user_present:
    - name: {{ salt['pillar.get']('nova:service:user', 'nova') }}
    - password: {{ salt['pillar.get']('nova:service:password', '0cc90602a527c5ab3fe8') }}
    - email: {{ salt['pillar.get']('nova:service:email', 'nova@localhost') }}
    - roles:
      - {{ salt['pillar.get']('nova:service:tenant', 'service') }}:
        - admin
    - require:
      - nova-tenant
    - require_in:
      {% for nova in nova_serv %}
      - service: {{ nova }}
      {% endfor %}

nova-service:
  keystone.service_present:
    - name: nova
    - service_type: compute
    - description: OpenStack Compute

nova-endpoint:
  keystone.endpoint_present:
    - name: nova
    - publicurl: {{ salt['pillar.get']('nova:endpoint:public', nova_endpoint ) }}
    - internalurl: {{ salt['pillar.get']('nova:endpoint:internal', nova_endpoint ) }}
    - adminurl: {{ salt['pillar.get']('nova:endpoint:admin', nova_endpoint ) }}
    - region: {{ region }}
    - require:
      - keystone: nova-service
    - require_in:
      {% for nova in nova_serv %}
      - service: {{ nova }}
      {% endfor %}

ec2-service:
  keystone.service_present:
    - name: ec2
    - service_type: ec2
    - description: OpenStack EC2 service

ec2-endpoint:
  keystone.endpoint_present:
    - name: ec2
    - publicurl: {{ salt['pillar.get']('nova:ec2:public', ec2_endpoint ) }}
    - internalurl: {{ salt['pillar.get']('nova:ec2:internal', ec2_endpoint ) }}
    - adminurl: {{ salt['pillar.get']('nova:ec2:admin', ec2_endpoint ) }}
    - region: {{ region }}
    - require:
      - keystone: ec2-service
    - require_in:
      {% for nova in nova_serv %}
      - service: {{ nova }}
      {% endfor %}
