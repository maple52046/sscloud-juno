nova-db:
  pkg.installed:
    - pkgs:
      - python-psycopg2
    - require_in:
      - cmd: nova
  postgres_user.present:
    - name: {{ salt['pillar.get']('nova:database:user', 'nova') }}
    - password: {{ salt['pillar.get']('nova:database:password', 'myN0V2p255wd') }}
    - require_in:
      - cmd: nova
  postgres_database.present:
    - name: {{ salt['pillar.get']('nova:database:name', 'nova') }}
    - owner: {{ salt['pillar.get']('nova:database:user', 'nova') }}
    - require:
      - postgres_user: nova-db
    - require_in:
      - cmd: nova
