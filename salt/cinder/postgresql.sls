cinder-db:
  pkg.installed:
    - pkgs:
      - python-psycopg2
    - require_in:
      - cmd: cinder
  postgres_user.present:
    - name: {{ salt['pillar.get']('cinder:database:user', 'cinder') }}
    - password: {{ salt['pillar.get']('cinder:database:password', 'myC1NDERp255wd') }}
    - require_in:
      - cmd: cinder
  postgres_database.present:
    - name: {{ salt['pillar.get']('cinder:database:name', 'cinder') }}
    - owner: {{ salt['pillar.get']('cinder:database:user', 'cinder') }}
    - require:
      - postgres_user: cinder-db
    - require_in:
      - cmd: cinder
