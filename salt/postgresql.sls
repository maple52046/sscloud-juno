postgresql:
  pkg.installed:
    - pkgs:
      - postgresql
      - postgresql-contrib
  file.append:
    - name: /etc/postgresql/9.3/main/postgresql.conf
    - text:
        listen_addresses = '*'
        max_connection = 1000
    - require:
      - pkg: postgresql
  service.running:
    - enable: False
    - reload: True
    - require:
      - pkg: postgresql
    - watch:
      - file: postgresql

# echo "host all all IPADDR trust" to /etc/postgresql/9.3/main/pg_hba.conf
/etc/postgresql/9.3/main/pg_hba.conf:
  file.append:
    - text:
        host all all all trust
    - require:
      - pkg: postgresql
    - watch_in:
      - service: postgresql
