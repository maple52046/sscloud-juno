base:
  '*':
    - ntp
    - openstack.ubuntu-cloud-keyring
    - openstack.user

controller:
  '*':
    - rabbitmq
    - {{ salt['pillar.get']('openstack:database:backend', 'postgresql') }}
    - keystone.service
    - glance.service
    - cinder.service
    - dashboard.service

network:
  '*':
    - neutron.service

compute:
  '*':
    - nova.service
    - neutron.service
