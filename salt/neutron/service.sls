{% set server_node = salt['pillar.get']('neutron:node:server', salt['pillar.get']('openstack:controller', 'localhost')) %}
{% set network_nodes = salt['pillar.get']('neutron:node:network', [salt['pillar.get']('openstack:controller', 'localhost')]) %}
{% set netowrk_services = ['neutron-l3-agent','neutron-dhcp-agent','neutron-metadata-agent'] %}

{% if grains['host'] == server_node %}
neutron-server:
  service.running:
    - name: neutron-server
    - enable: False
    - reload: True
{% endif %}

{% if grains['host'] in network_nodes %}
{% for serv in network_services %}
{{ serv }}:
  service.running:
    - enable: False
    - reload: True
    {% if grains['host'] == network_server %}
    - require:
      - service: neutron-server
    {% endif %}
{% endfor %}
{% endif %}

{% for serv in ['neutron-ovs-cleanup','neutron-plugin-openvswitch-agent'] %}
{{ serv }}:
  service.running:
    - enable: False
    - reload: True
{% endfor %}
