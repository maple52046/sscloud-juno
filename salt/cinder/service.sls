{% for cinder in ['cinder-api','cinder-scheduler'] %}
{{ cinder }}:
  service.running:
    - enable: False
    - reload: True
{% endfor %}
