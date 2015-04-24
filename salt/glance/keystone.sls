glance-user:
  keystone.user_present:
    - name: {{ salt['pillar.get']('glance:service:user', 'glance') }}
    - password: {{ salt['pillar.get']('glance:service:password', '0cc90602a527c5ab3fe8'}}
    - email: {{ salt['pillar.get']('glance:service:email', 'glance@localhost' }}
    - roles:
      - service:
        - admin
    - require_in:
      - service: glance-api
      - service: glance-registry

glance-service:
  keystone.service_present:
    - name: glance
    - service_type: image
    - description: OpenStack Image Service

glance-endpoint:
  keystone.endpoint_present:
    - name: glance
    - publicurl: {{ pillar['glance']['endpoint']['public'] }}
    - internalurl: {{ pillar['glance']['endpoint']['internal'] }}
    - adminurl: {{ pillar['glance']['endpoint']['admin'] }}
    - region: {{ pillar['glance']['region'] }}
    - require:
      - keystone: glance-service
    - require_in:
      - service: glance-api
      - service: glance-registry
