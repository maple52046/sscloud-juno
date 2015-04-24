{% set db_backend = salt['pillar.get']('cinder:database:backend', 'postgresql') %}

include:
  - cinder.keystone
  - cinder.service
  {% if db_backend in ['postgresql'] %}
  - cinder.{{ dbbackend }}
  {% endif %}

cinder:
  pkg.installed:
    - pkgs:
      - cinder-api
      - cinder-scheduler
      - python-cinderclient
    - require:
      - file: cinder
  cmd.run:
    - name: cinder-manage db sync
    - require:
      - pkg: cinder
    - watch:
      - file: cinder
    - require_in:
      - service: cinder-api
      - service: cinder-scheduler
  file.managed:
    - name: /etc/cinder/cinder.conf
    - source: salt://cinder/cinder.conf
    - template: jinja
    - watch_in:
      - service: cinder-api
      - service: cinder-scheduler
    - context:
        rabbit_host: {{ salt['pillar.get']('cinder:rabbitmq:host', 'localhost') }}
        rabbit_user: {{ salt['pillar.get']('cinder:rabbitmq:user', 'cinder' )}}
        rabbit_pass: {{ salt['pillar.get']('cinder:rabbitmq:password', 'cinder') }}
        rabbit_vhost: {{ salt['pillar.get']('cinder:rabbbitmq:vhost', 'cinder') }}
        glance_host: {{ salt['pillar.get']('glance:host', salt['pillar.get']('openstack:controller','localhost')) }}
        db_backend: {{ db_backend }}
        db_user: {{ salt['pillar.get']('cinder:database:user', 'cinder') }}
        db_pass: {{ salt['pillar.get']('cinder:database:password', 'myC1NDERp255wd') }}
        db_host: {{ salt['pillar.get']('cinder:database:host', 'localhost') }}
        db_name: {{ salt['pillar.get']('cinder:database:name', 'cinder') }}
        keystone_admin_uri: {{ salt['pillar.get']('keystone:endpoint:admin', 'http://localhost:35357/v2.0').split('/v2.0')[0] }}
        keystone_internal_url: {{ salt['pillar.get']('keystone:endpoint:internal', 'http://localhost:5000/v2.0') }}
        cinder_tenant: {{ salt['pillar.get']('cinder:service:tenant', 'service') }}
        cinder_user: {{ salt['pillar.get']('cinder:service:user', 'cinder')}}
        cinder_pass: {{ salt['pillar.get']('cinder:service:password', '0cc90602a527c5ab3fe8') }}

extend:
{% for cinder in ['cinder-api','cinder-scheduler'] %}
  {{ cinder }}:
    file.symlink:
      - name: /etc/init.d/{{ cinder }}
      - target: /lib/init/upstart-job
{% endfor %}
