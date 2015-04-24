{% set rootpw = salt['pillar.get']('mysql:root:password', salt['pillar.get']('openstack:admin:password', 'myR00Twd')) %}

mysql-server:
  debconf.set:
    - name: mysql-server
    - data:
        'mysql-server/root_password_again': {'type':'password', 'value': "{{ rootpw }}"}
        'mysql-server/root_password': {'type':'password', 'value': "{{ rootpw }}"}
  pkg.installed:
    - pkgs:
      - mysql-server
    - require:
      - debconf: mysql-server
