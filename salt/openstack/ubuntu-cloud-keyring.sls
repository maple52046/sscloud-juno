ubuntu-cloud-keyring:
  pkgrepo.managed:
    - name: "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main"
    - file: /etc/apt/sources.list.d/cloudarchive-juno.list
  pkg.latest:
    - refresh: True
    - require:
      - pkgrepo: ubuntu-cloud-keyring
