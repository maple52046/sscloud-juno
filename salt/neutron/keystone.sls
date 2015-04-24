neutron-user:
  keystone.user_present:
    - name: neutron
    - email: neutron@localhost
    - password: {{ pillar['keystone']['token'] }}
    - roles:
      - service:
        - admin
    - require_in:
      - service: neutron-server

neutron-service:
  keystone.service_present:
    - name: neutron
    - service_type: network
    - description: OpenStack Networking

neutron-endpoint:
  keystone.endpoint_present:
    - name: neutron
    - publicurl: {{ pillar['neutron']['endpoint']['public'] }}
    - internalurl: {{ pillar['neutron']['endpoint']['internal'] }}
    - adminurl: {{ pillar['neutron']['endpoint']['admin'] }}
    - region: {{ pillar['keystone']['region'] }}
    - require:
      - keystone: neutron-service
    - require_in:
      - service: neutron-server
