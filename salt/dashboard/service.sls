gunicorn:
  service.running:
    - enable: False
    - reload: True

nginx:
  service.running:
    - enable: False
    - reload: True
    - require:
      - service: gunicorn
