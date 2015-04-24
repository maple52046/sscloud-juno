# Install RabbitMQ server
rabbitmq-server:
  pkgrepo.managed:
    - name: deb http://www.rabbitmq.com/debian/ testing main
    - file: /etc/apt/sources.list.d/rabbitmq.list
    - key_url: https://www.rabbitmq.com/rabbitmq-signing-key-public.asc
  pkg.installed:
    - refresh: True
    - require:
      - pkgrepo: rabbitmq-server
  rabbitmq_plugin.enabled:
    - name: rabbitmq_management
    - require:
      - pkg: rabbitmq-server
  service.running:
    - enable: True
    - reload: True
    - require:
      - pkg: rabbitmq-server
    - watch:
      - rabbitmq_plugin: rabbitmq-server

# Delete guest and create admin user
rabbitmq_guest:
  rabbitmq_user.absent:
    - name: guest
    - require:
      - rabbitmq_user: rabbitmq_admin

rabbitmq_admin:
  rabbitmq_user.present:
    - name: {{ salt['pillar.get']('rabbitmq:admin:user', salt['pillar.get']('openstack:admin:user', 'admin')) }}
    - password: {{ salt['pillar.get']('rabbitmq:admin:password', salt['pillar.get']('openstack:admin:password', 'sscloudadmin')) }}
    - force: True
    - perms:
      - '/':
        - '.*':
        - '.*':
        - '.*':
    - tags:
      - administrator
      - management
    - require:
      - service: rabbitmq-server

# Create user and vhost for OpenStack service
{% for service in ['glance','cinder','nova','neutron'] %}
openstack_rabbit_user_{{ service }}:
  rabbitmq_user.present:
    - name: {{ salt['pillar.get'](service+':rabbitmq:user', service) }}
    - password: {{ salt['pillar.get'](service+':rabbitmq:password', service) }}
    - force: True
    - tags:
      - management
      - user
    - require:
      - service: rabbitmq-server

openstack_rabbit_vhost_{{ service }}:
  rabbitmq_vhost.present:
    - name: {{ salt['pillar.get'](service+':rabbitmq:vhost', service) }}
    - user: {{ salt['pillar.get'](service+':rabbitmq:user', service) }}
    - owner: {{ salt['pillar.get'](service+':rabbitmq:user', service) }}
    - conf: .*
    - write: .*
    - read: .*
    - require:
      - rabbitmq_user: openstack_rabbit_user_{{ service }}
{% endfor %}
