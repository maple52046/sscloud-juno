ntp:
  pkg.installed:
    - require:
      - file: ntp
  file.managed:
    - name: /etc/ntp.conf
    - template: jinja
    - source: salt://ntp/ntp.conf
  service.running:
    - enable: True
    - reload: True
    - require:
      - pkg: ntp
    - watch:
      - file: ntp
