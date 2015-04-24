{% for glance in ['glance-api','glance-registry'] %}
{{ glance }}:
  service.running:
    - enable: False
    - reload: True
{% endfor %}
