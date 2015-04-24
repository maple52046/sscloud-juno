{% set server_node = salt['pillar.get']('neutron:node:server', salt['pillar.get']('openstack:controller', 'localhost')) %}
{% set network_nodes = salt['pillar.get']('neutron:node:network', [salt['pillar.get']('openstack:controller', 'localhost')]) %}
{% set network_services = ['neutron-l3-agent','neutron-dhcp-agent','neutron-metadata-agent'] %}
{% set network_configs = {'neutron-l3-agent':'l3_agent.ini','neutron-dhcp-agent':'dhcp_agent.ini','neutron-metadata-agent':'metadata_agent.ini'} %}

{% set neutron_service_tenant = salt['pillar.get']('neutron:service:tenant', 'service') %}
{% set neutron_service_user = salt['pillar.get']('neutron:service:user', 'neutron') %}
{% set neutron_service_password = salt['pillar.get']('neutron:service:password', salt['pillar.get']('openstack:admin:token', '0cc90602a527c5ab3fe8')) %}

{% set db_backend = salt['pillar.get']('neutron:database:backend', 'postgresql') %}
include:
  {% if grains['host'] == server_node %}
  - neutron.keystone
  - neutron.{{ db_backend }}
  {% endif %}
  - neutron.service

neutron:
  file.managed:
    - name: /etc/neutron/neutron.conf
    - source: salt://neutron/neutron.conf
    - template: jinja
    - context:
        nova_url: {{ salt['pillar.get']('nova:endpoint:internal', 'http://' + salt['pillar.get']('openstack:controller', 'localhost') + ':8774/v2.0/%(tenant_id)s').split('/%')[0] }}
        nova_region: {{ salt['pillar.get']('nova:region', salt['pillar.get']('openstack:region','regionOne')) }}
        nova_service_user: {{ salt['pillar.get']('nova:service:user', 'nova') }}
        nova_service_tenant_id: {{ grains['sscloud']['nova']['tenant_id'] }}
        nova_service_password: {{ salt['pillar.get']('nova:service:password', salt['pillar.get']('openstack:admin:token','0cc90602a527c5ab3fe8')) }}
        keystone_endpoint: {{ salt['pillar.get']('keystone:endpoint:internal', 'http://' + salt['pillar.get']('openstack:controller', 'localhost') + ':5000/v2.0' ) }}
        keystone_host: {{ salt['pillar.get']('keystone:host', salt['pillar.get']('openstack:controller', 'localhost')) }}
        rpc_backend: {{ salt['pillar.get']('neutron:rpc:backend', 'rabbit') }}
        rabbit_host: {{ salt['pillar.get']('neutron:rabbitmq:host', salt['pillar.get']('openstack:controller', 'localhost')) }}
        rabbit_user: {{ salt['pillar.get']('neutron:rabbitmq:user', 'neutron')) }}
        rabbit_pass: {{ salt['pillar.get']('neutron:rabbitmq:pass', 'neutron')) }}
        rabbit_vhost: {{ salt['pillar.get']('neutron:rabbitmq:vhost', 'neutron')) }}
        neutron_service_tenant: {{ neutron_service_tenant }}
        neutron_service_user: {{ neutron_service_user }}
        neutron_service_password: {{ neutron_service_password }}
        db_backend: {{ db_backend }}
        db_user: {{ salt['pillar.get']('neutron:database:user', 'neutron') }}
        db_pass: {{ salt['pillar.get']('neutron:database:password', 'myNEUTR0Np255wd') }}
        db_host: {{ salt['pillar.get']('neutron:database:host', salt['pillar.get']('openstack:controller', 'localhost')) }}
        db_name: {{ salt['pillar.get']('neutron:database:name', 'neutron') }}
    - watch_in:
      {% if grains['host'] == server_node %}
      - service: neutron-server
      {% endif %}
      {% if grains['host'] in network_nodes %}
      {% for serv in network_servers %}
      - service: {{ serv }}
      {% endfor %}
      {% endif %}
  pkg.installed:
    - pkgs:
      {% if grains['host'] == server_node %}
      - neutron-server
      - python-neutronclient
      {% endif %}
      {% if grains['host'] in network_nodes %}
      - neutron-l3-agent
      - neutron-dhcp-agent
      - neutron-metadata-agent
      {% endif %}
      - neutron-plugin-ml2
      - neutron-plugin-openvswitch-agent
      - openvswitch-switch
    - require:
      - file: neutron
      - file: ml2
    - require_in:
      {% if grains['host'] == server_node %}
      - service: neutron-server
      {% endif %}
      {% if grains['host'] in network_nodes %}
      {% for serv in network_services %}
      - service: {{ serv }}
      {% endfor %}
      {% endif %}
      - service: neutron-plugin-openvswitch-agent
  {% if grains['host'] == server_node %}
  cmd.run:
    - name: neutron-db-manage --config-file /etc/neutron/neutron.conf upgrade juno
    - require:
      - file: neutron
      - file: ml2
      - pkg: neutron
    - require_in:
      - service: neutron-server
  {% endif %}

ml2:
  file.managed:
    - name: /etc/neutron/plugins/ml2/ml2_conf.ini
    - source: salt://neutron/ml2_conf.ini
    - template: jinja

extend:
  {% if grains['host'] == server_node %}
  neutron-server:
    file.symlink:
      - name: /etc/init.d/neutron-server
      - target: /lib/init/upstart-job
  {% endif %}
  {% if grains['host'] in network_nodes %}
  {% for serv in network_services %}
  {{ network_configs[serv] }}:
    file.managed:
      - name: /etc/neutron/{{ network_configs[serv] }}
      - source: salt://neutron/{{ network_configs[serv] }}
      - template: jinja
      - watch_in:
        - service: {{ serv }}
      - context:
          keystone_endpoint: {{ salt['pillar.get']('keystone:endpoint:internal', 'http://' + salt['pillar.get']('openstack:controller', 'localhost') + ':5000/v2.0' ) }}
          neutron_region: {{ salt['pillar.get']('neutron:region', salt['pillar.get']('openstack:region', 'regionOne')) }}
          neutron_service_tenant: {{ neutron_service_tenant }}
          neutron_service_user: {{ neutron_service_user }}
          neutron_service_password: {{ neutron_service_password }}
          nova_host: {{ salt['pillar.get']('nova:host', salt['pillar.get']('openstack:controller')) }}
          metadata_secret: {{ salt['pillar.get']('nova:metadata:secret', 'SScloud') }}

  {{ serv }}-upstart:
    file.symlink:
      - name: /etc/init.d/{{ serv }}
      - target: /lib/init/upstart-job
  {% endfor %}
  {% endif %}
  {% for serv in ['neutron-ovs-cleanup','neutron-plugin-openvswitch-agent'] %}
  {{ serv }}:
    file.symlink:
      - name: /etc/init.d/{{ serv }}
      - target: /lib/init/upstart-job
  {% endfor %}
    
{% if grains['host'] in network_nodes %}
/etc/neutron/dnsmasq.conf:
  file.managed:
    - source: salt://neutron/dnsmasq.conf
    - tempalte: jinja
    - require_in:
      - service: neutron-dhcp-agent
{% endif %}

{% if grains['host'] == server_node or grains['host'] in network_nodes %}
net.ipv4.ip_forward:
  sysctl.present:
    - value: 1
    - require_in:
      {% if grains['host'] == server_node %}
      - service: neutron-server
      {% endif %}
      {% if grains['host'] in network_nodes %}
      - service: neutron-l3-agent
      - service: neutron-dhcp-agent
      {% endif %}
{% endif %}

net.ipv4.conf.all.rp_filter:
  sysctl.present:
    - value: 0
    - require_in:
      - service: neutron-plugin-openvswitch-agent

net.ipv4.conf.default.rp_filter:
  sysctl.present:
    - value: 0
    - require_in:
      - service: neutron-plugin-openvswitch-agent

"ovs-vsctl --may-exists add-br br-tun":
  cmd.run:
    - require_in:
      - service: neutron-plugin-openvswitch-agent
