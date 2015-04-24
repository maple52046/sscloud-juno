cinder-user:
  keystone.user_present:
    - name: {{ salt['pillar.get']('cinder:service:user', 'cinder') }}
    - password: {{ salt['pillar.get']('cinder:service:password', '0cc90602a527c5ab3fe8') }}
    - email: {{ salt['pillar.get']('cinder:service:email', 'cinder@localhost') }}
    - roles:
      - {{ salt['pillar.get']('cinder:service:tenant', 'service') }}:
        - admin
    - require_in:
      - service: cinder-api
      - service: cinder-scheduler

cinder-service:
  keystone.service_present:
    - name: cinder
    - service_type: volume
    - description: OpenStack Block Storage

cinder-endpoint:
  keystone.endpoint_present:
    - name: cinder
    - publicurl: {{ salt['pillar.get']('cinder:endpoint:v1:public', "http://" + grains['fqdn_ip4'][0] + ":8776/v1/%(tenant_id)s") }}
    - internalurl: {{ salt['pillar.get']('cinder:endpoint:v1:internal', "http://" + grains['fqdn_ip4'][0] + ":8776/v1/%(tenant_id)s") }}
    - adminurl: {{ salt['pillar.get']('cinder:endpoint:v1:admin', "http://" + grains['fqdn_ip4'][0] + ":8776/v1/%(tenant_id)s") }}
    - region: {{ salt['pillar.get']('cinder:region', 'regionOne') }}
    - require:
      - keystone: cinder-service
    - require_in:
      - service: cinder-api
      - service: cinder-scheduler

cinder2-service:
  keystone.service_present:
    - name: cinderv2
    - service_type: volumev2
    - description: OpenStack Block Storage

cinder2-endpoint:
  keystone.endpoint_present:
    - name: cinderv2
    - publicurl: {{ salt['pillar.get']('cinder:endpoint:v2:public', 'http://' + grains['fqdn_ip4'][0] + ':8776/v2/%(tenant_id)s') }}
    - internalurl: {{ salt['pillar.get']('cinder:endpoint:v2:internal', 'http://' + grains['fqdn_ip4'][0] + ':8776/v2/%(tenant_id)s') }}
    - adminurl: {{ salt['pillar.get']('cinder:endpoint:v2:admin', 'http://' + grains['fqdn_ip4'][0] + ':8776/v2/%(tenant_id)s') }}
    - region: {{ salt['pillar.get']('cinder:region', 'regionOne') }}
    - require:
      - keystone: cinder2-service
    - require_in:
      - service: cinder-api
      - service: cinder-scheduler
