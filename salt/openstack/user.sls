{% for uname in pillar['openstack']['system'] %}
{{ uname }}:
  group.present:
    - name: {{ pillar['openstack']['system'][uname]['groupname'] }}
    - gid: {{ pillar['openstack']['system'][uname]['gid'] }}
  user.present:
    - name: {{ uname }}
    - uid: {{ pillar['openstack']['system'][uname]['uid'] }}
    - gid: {{ pillar['openstack']['system'][uname]['gid'] }}
    - home: {{ pillar['openstack']['system'][uname]['home'] }}
    - shell: /bin/false
    - createhome: False
    - require:
      - group: {{ uname }}
{% endfor %}
