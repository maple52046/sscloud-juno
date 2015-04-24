{% if grains['host'] == pillar['nova']['host'] %}
{% for nova in ['nova-api','nova-cert', 'nova-conductor', 'nova-consoleauth','nova-novncproxy', 'nova-scheduler'] %}
{{ nova }}:
  service.running:
    - enable: False
    - reload: True
    - watch:
      - file: nova
{% endfor %}
{% endif %}

{% if grains['host'] in pillar['nova']['compute'] %}
nova-compute:
  service.running:
    - enable: False
    - reload: True
    - watch:
      - file: nova
{% endif %}
