neutron-db:
  pkg.installed:
    - pkgs:
      - python-psycopg2
    - require_in:
      - cmd: neutron
  postgres_user.present:
    - name: {{ salt['pillar.get']('neutron:database:user','neutron') }}
    - password: {{ salt['pillar.get']('neutron:database:password','myNEUTR0Np255wd') }}
    - require_in:
      - cmd: neutron
  postgres_database.present:
    - name: {{ salt['pillar.get']('neutron:database:name', 'neutron') }}
    - owner: {{ salt['pillar.get']('neutron:database:user', 'neutron') }}
    - require:
      - postgres_user: neutron-db
    - require_in:
      - cmd: neutron
