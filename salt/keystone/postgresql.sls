keystone-db:
  pkg.installed:
    - name: python-psycopg2
    - require_in:
      - postgres_user: keystone-db
      - postgres_database: keystone-db
  postgres_user.present:
    - name: {{ salt['pillar.get']('keystone:database:user', 'keystone') }}
    - password: {{ salt['pillar.get']('keystone:database:password', 'myKEY5T0NEp255wd') }}
    - require_in:
      - cmd: keystone
      - postgres_database: keystone-db
  postgres_database.present:
    - name: {{ salt['pillar.get']('keystone:database:host', salt['pillar.get']('openstack:controller', 'localhost')) }}
    - owner: {{ salt['pillar.get']('keystone:database:user', 'keystone') }}
    - require_in:
      - cmd: keystone
