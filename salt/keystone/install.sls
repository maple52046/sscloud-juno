include:
  - keystone.{{ salt['pillar.get']('keystone:database:backend', 'postgresql') }}
  - keystone.service

extend:
  keystone:
    pkg.installed:
      - pkgs:
        - keystone
        - python-keystoneclient
        - python-memcache
        - memcached
      - require_in:
        - service: keystone
        - cmd: keystone
      - require:
        - file: keystone
    cmd.run:
      - name: keystone-manage db_sync
      - watch:
        - file: keystone
      - require_in:
        - service: keystone
    file.managed:
      - name: /etc/keystone/keystone.conf
      - source: salt://keystone/keystone.conf
      - template: jinja
      - watch_in:
        - service: keystone
      - context:
          admin_token: {{ salt['pillar.get']('openstack:admin:token', '0cc90602a527c5ab3fe8') }}
          dbbackend: {{ salt['pillar.get']('keystone:database:backend', 'postgresql') }}
          dbuser: {{ salt['pillar.get']('keystone:database:user', 'keystone') }}
          dbpass: {{ salt['pillar.get']('keystone:database:password', 'myKEY5T0NEp255wd') }}
          dbname: {{ salt['pillar.get']('keystone:database:name', 'keystone') }}
          dbhost: {{ salt['pillar.get']('keystone:database:host', salt['pillar.get']('openstack:controller', 'localhost')) }}

/etc/init.d/keystone:
  file.symlink:
    - target: /lib/init/upstart-job
