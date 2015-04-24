/root/adminrc:
  file.managed:
    - name: /root/adminrc
    - source: salt://credentials/adminrc
    - template: jinja
    - mode: 0750

/root/.profile:
  file.append:
    - text:
        test -f /root/adminrc && source /root/adminrc

/root/openrc:
  file.managed:
    - name: /root/openrc
    - source: salt://credentials/openrc
    - template: jinja
    - mode: 0750
