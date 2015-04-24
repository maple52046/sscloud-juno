{% set rootpw = salt['pillar.get']('mariadb:root:password', salt['pillar.get']('mysql:root:password', salt['pillar.get']('openstack:admin:password', 'myR00Twd'))) %}

mariadb-server:
  pkgrepo.managed:
    - humanname: MariaDB repo
    - name: "deb http://ftp.yz.yamagata-u.ac.jp/pub/dbms/mariadb/repo/10.0/ubuntu trusty main"
    - file: /etc/apt/sources.list.d/mariadb.list
    - dist: trusty
    - keyid: 1BB943DB
    - keyserver: keyserver.ubuntu.com
  debconf.set:
    - name: mariadb-server-10.0
    - data:
        'mysql-server/root_password_again': {'type':'password', 'value': "{{ rootpw }}"}
        'mysql-server/root_password': {'type':'password', 'value': "{{ rootpw }}"}
  pkg.installed:
    - pkgs:
      - mariadb-server-10.0
    - refresh: True
    - require:
      - debconf: mariadb-server
      - pkgrepo: mariadb-server
