{% set dbbackend = salt['pillar.get']('keystone:database:backend', 'postgresql') %}
{% set dbuser = salt['pillar.get']('keystone:database:user', 'glance') %}
{% set dbpass = salt['pillar.get']('keystone:database:password', 'my912NCEp255wd') %}
{% set dbname = salt['pillar.get']('keystone:database:name', 'glance') %}
{% set dbhost = salt['pillar.get']('keystone:database:name', 'localhost') %}

include:
  - glance.keystone
  {% if salt['pillar.get']('keystone:database:backend', 'postgresql') in ['postgresql'] %}
  - glance.postgresql
  {% endif %}
  - glance.service

glance:
  pkg.installed:
    - pkgs:
      - glance
      - python-glanceclient
    - require:
      - file: glance-api
      - file: glance-registry
  cmd.run:
    - name: glance-manage db_sync
    - require:
      - pkg: glance
    - watch:
      - file: glance-api
      - file: glance-registry
    - require_in:
      - service: glance-api
      - service: glance-registry

{% for glance in ['glance-api','glance-registry'] %}
/etc/init.d/{{ glance }}:
  file.symlink:
    - target: /lib/init/upstart-job

extend:
  {{ glance }}
    file.managed:
      - name: /etc/glance/{{ glance }}.conf
      - source: salt://glance/{{ glance }}.conf
      - template: jinja
      - watch_in:
        - service: {{ glance }}
{% endfor %}
