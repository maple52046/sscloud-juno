service:
  keystone.tenant_present:
    - description: "OpenStack Service"

Member:
  keystone:
    - role_present

admin-tenant:
  keystone.tenant_present:
    - name: {{ salt['pillar.get']('openstack:admin:tenant', 'admin') }}
    - description: "Administrator"

admin-role:
  keystone.role_present:
    - name: admin

admin-user:
  keystone.user_present:
    - name: {{ salt['pillar.get']('openstack:admin:user', 'admin') }}
    - password: {{ salt['pillar.get']('openstack:admin:password', 'sscloudadmin') }}
    - email: {{ salt['pillar.get']('openstack:admin:email', 'admin@localhost') }}
    - roles:
      - {{ salt['pillar.get']('openstack:admin:tenant', 'admin') }}:
        - admin
    - require:
      - keystone: admin-tenant
      - keystone: admin-role

keystone-service:
  keystone.service_present:
    - name: keystone
    - service_type: identity
    - description: OpenStack Identity

keystone-endpoint:
  keystone.endpoint_present:
    - name: keystone
    - publicurl: {{ salt['pillar.get']('keystone:endpoint:public', "http://" + grains['fqdn_ip4'][-1] + "/keystone/v2.0") }}
    - internalurl: {{ salt['pillar.get']('keystone:endpoint:internal', "http://" + grains['fqdn_ip4'][-1] + ":5000/v2.0") }}
    - adminurl: {{ salt['pillar.get']('keystone:endpoint:admin', "http://" + grains['fqdn_ip4'][-1] + ":35357/v2.0") }}
    - region: {{ salt['pillar.get']('keystone:region', 'regionOne') }}
    - require:
      - keystone: keystone-service
