glance-db:
  pkg.installed:
    - pkgs:
      - python-psycopg2
    - require_in:
      - cmd: glance
  postgres_user.present:
    - name: {{ salt['pillar.get']('keystone:database:user', 'glance') }}
    - password: {{ salt['pillar.get']('keystone:database:password', 'my912NCEp255wd') }}
    - require_in:
      - cmd: glance
  postgres_database.present:
    - name: {{ salt['pillar.get']('keystone:database:name', 'glance') }}
    - owner: {{ salt['pillar.get']('keystone:database:user', 'glance') }}
    - require:
      - postgres_user: glance-db
    - require_in:
      - cmd: glance
