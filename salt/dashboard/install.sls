include:
  - dashboard.service

openstack-dashboard:
  pkgrepo.managed:
    - ppa: nginx/stable
    - require_in:
      - pkg: openstack-dashboard
  pkg.installed:
    - pkgs:
      - openstack-dashboard
      - memcached
      - python-memcache
      - nginx
      - gunicorn
    - require_in:
      - service: gunicorn
      - service: nginx
  file.directory:
    - name: /var/run/openstack-dashboard/
    - user: horizon
    - group: horizon
    - require:
      - pkg: openstack-dashboard

openstack-dashboard-ubuntu-theme:
  pkg.removed:
    - require:
      - pkg: openstack-dashboard
    - require_in:
      - service: gunicorn
      - service: nginx

{% for index in range(grains['num_cpus']) %}
/etc/gunicorn.d/horizon.{{ index }}:
  file.managed:
    - source: salt://dashboard/gunicorn.conf
    - template: jinja
    - context:
        process_index: {{ index }}
    - require:
      - pkg: openstack-dashboard
      - file: openstack-dashboard
    - require_in:
      - service: gunicorn
{% endfor %}

/etc/nginx/sites-available/horizon:
  file.managed:
    - source: salt://dashboard/nginx
    - template: jinja
    - watch_in:
      - file: nginx

#/etc/nginx/sites-enabled/default:
#  file.absent:
#    - require_in:
#      - service: nginx

/etc/nginx/sites-enabled/horizon:
  file.symlink:
    - target: /etc/nginx/sites-available/horizon
    - require:
      - file: /etc/nginx/sites-available/horizon
    - watch_in:
      - service: nginx

{% if salt['pillar.get']('openstack:horizon:prefix', '/') != '/horizon' %}
LOGIN_URL:
  file.sed:
    - name: /etc/openstack-dashboard/local_settings.py
    - before: /horizon/auth/login/
    - after: {{ salt['pillar.get']('openstack:horizon:prefix', '/') }}
    - limit: ^LOGIN_URL=
    - require:
      - pkg: openstack-dashboard
    - require_in:
      - service: gunicorn

LOGIN_REDIRECT_URL:
  file.sed:
    - name: /etc/openstack-dashboard/local_settings.py
    - before: /horizon
    - after: {{ salt['pillar.get']('openstack:horizon:prefix', '/') }}
    - limit: ^LOGIN_REDIRECT_URL=
    - require:
      - pkg: openstack-dashboard
    - require_in:
      - service: gunicorn
{% endif %}

SESSION_TIMEOUT:
  file.append:
    - name: /etc/openstack-dashboard/local_settings.py
    - text: SESSION_TIMEOUT = 1800
    - require:
      - pkg: openstack-dashboard
    - require_in:
      - service: gunicorn

TOKEN_TIMEOUT_MARGIN:
  file.managed:
    - name: /etc/openstack-dashboard/local_settings.py
    - text: TOKEN_TIMEOUT_MARGIN = 10
    - require:
      - pkg: openstack-dashboard
    - require_in:
      - service: gunicorn
