{% set nova_host = salt['pillar.get']('nova:host', salt['pillar.get']('openstack:controller', 'localhost')) %}
{% set nova_compute = salt['pillar.get']('nova:compute', salt['pillar.get']('openstack:compute', ['localhost'])) %}
{% set controller_service = ['nova-api','nova-cert', 'nova-conductor', 'nova-consoleauth','nova-novncproxy', 'nova-scheduler'] %}

include:
  {% if grains['host'] == nova_host %}
  - nova.keystone
  {% if salt['pillar.get']('nova:database:backend', 'postgresql') in ['postgresql'] %}
  - nova.postgresql
  {% endif %}
  {% endif %}
  - nova.service

nova:
  file.managed:
    - name: /etc/nova/nova.conf
    - source: salt://nova/nova.conf
    - template: jinja
    - context:
        rpc_backend: {{ salt['pillar.get']('nova:rpc:backend','rabbit') }}
        rabbitmq_host: {{ salt['pillar.get']('nova:rabbitmq:host', salt['pillar.get']('openstack:controller', 'localhost')) }}
        rabbitmq_user: {{ salt['pillar.get']('nova:rabbitmq:user', 'nova') }}
        rabbitmq_pass: {{ salt['pillar.get']('nova:rabbitmq:password', 'nova') }}
        rabbitmq_vhost: {{ salt['pillar.get']('nova:rabbitmq:vhost', 'nova') }}
        db_backend: {{ salt['pillar.get']('nova:database:backend', 'postgresql') }}
        db_user: {{ salt['pillar.get']('nova:database:user', 'nova') }}
        db_pass: {{ salt['pillar.get']('nova:database:password', 'myN0V2p255wd') }}
        db_name: {{ salt['pillar.get']('nova:database:name', 'nova') }}
        db_host: {{ salt['pillar.get']('nova:database:host', salt['pillar.get']('openstack:controller', 'localhost')) }}
        keystone_admin_uri: {{ salt['pillar.get']('keystone:endpoint:admin', 'http://' + salt['pillar.get']('openstack:controller', 'localhost') + ':5000/v2.0') ).split('/v2.0')[0] }}
        keystone_internal_url: {{ salt['pillar.get']('keystone:endpoint:internal', 'http://' + salt['pillar.get']('openstack:controller', 'localhost') + ':5000/v2.0') }}
        nova_service_tenant: {{ salt['pillar.get']('nova:service:tenant', 'service') }}
        nova_service_user: {{ salt['pillar.get']('nova:service:user', 'nova') }}
        nova_service_password: {{ salt['pillar.get']('nova:service:password', '0cc90602a527c5ab3fe8') }}
        nova_metadata_secret: {{ salt['pillar.get']('nova:metadata:secret', 'SScloud') }}
        glance_host: {{ salt['pillar.get']('glance:host', salt['pillar.get']('openstack:controller', 'localhost')) }}
        neutron_endpoint: {{ salt['pillar.get']('neutron:endpoint:internal', 'http://' + salt['pillar.get']('openstack:controller', 'localhost') + ':9696') }}
        neutron_service_tenant: {{ salt['pillar.get']('neutron:service:tenant', 'service') }}
        neutron_service_user: {{ salt['pillar.get']('neutron:service:user', 'neutron') }}
        neutron_service_password: {{ salt['pillar.get']('neutron:service:password', '0cc90602a527c5ab3fe8') }}
        ec2_host: {{ salt['pillar.get']('nova:host', salt['pillar.get']('openstack:controller', 'localhost')) }}
        ec2_endpoint: {{ salt['pillar.get']('nova:ec2:internal', 'http://' + salt['pillar.get']('openstack:controller', 'localhost') + ':8773/services/Cloud') }}
        novnc_ssl: {{ salt['pillar.get']('nova:novnc:https', salt['pillar.get']('openstack:horizon:https:enable', False)) }}
        novnc_ssl_crt: {{ salt['pillar.get']('nova:novnc:crt', salt['pillar.get']('openstack:horizon:https:crt', '/etc/sscloud/ssl/sscloud.crt')) }}
        novnc_ssl_key: {{ salt['pillar.get']('nova:novnc:key', salt['pillar.get']('openstack:horizon:https:key', '/etc/sscloud/ssl/sscloud.key')) }}
        novnc_url: {{ salt['pillar.get']('nova:novnc:url', 'http://' + salt['pillar.get']('openstack:horizon:domain', salt['pillar.get']('openstack:controller', 'localhost'))  + ':6080/vnc_auto.html') }}
        nova_host: {{ nova_host }}
        nova_compute: {{ nova_compute }}
  pkg.installed:
    - pkgs:
      {% if grains['host'] == nova_host %}
      - nova-api
      - nova-cert
      - nova-conductor
      - nova-consoleauth
      - nova-novncproxy 
      - nova-scheduler
      - python-novaclient
      {% endif %}
      {% if grains['host'] in nova_compute %}
      - nova-compute
      - sysfsutils
      {% endif %}
    - require:
      - file: nova
  {% if grains['host'] == nova_host %}
  cmd.run:
    - name: nova-manage db sync
    - require:
      - pkg: nova
    - watch:
      - file: nova
    - require_in:
      {% for nova in  %}
      - service: {{ nova }}
      {% endfor %}
  {% endif %}

extend:
  {% if grains['host'] == nova_host %}
  {% for nova in controller_service %}
  {{ nova }}:
    file.symlink:
      - name: /etc/init.d/{{ nova }}
      - target: /lib/init/upstart-job
  {% endfor %}
  {% endif %}
  {% if grains['host'] in nova_compute %}
  nova-compute:
    file.symlink:
      - name: /etc/init.d/nova-compute
      - target: /lib/init/upstart-job
  {% endif %}
