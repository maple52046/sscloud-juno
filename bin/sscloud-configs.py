#!/opt/sscloud/bin/python

import logging
import netaddr
import netifaces
import os
import yaml

from jinja2 import Template
from platform import uname
from shutil import move
from socket import getfqdn
from subprocess import check_output

logger = logging.getLogger(__main__)

class configs:
	def __init__(self, config='/etc/sscloud/config.yml'):
		self.config = config

	def genconfig(self, admin, tenant, password, email=None, token=None, controller=None, compute=None, horizon_domain=None, enable_https=False, ssl_crt=None, ssl_key=None):
		base_dir = '/'.join(self.config.split('/')[:-1])
		if not os.path.exists(base_dir):
			os.makedirs(base_dir)

		if os.path.isfile(self.config):
			try:
				backup_orig = self.config + '.orig'
				move(self.config, backup_orig)
				logger.warning('%s is already exist. Move file to %s',self.config, back_orig)
			except Exception, err:
				logger.error('Unknown error: %s', str(err))

		with open('/opt/sscloud/etc/sscloud/config.sample.yml', 'r') as f:
			template = Template(f.readlines())

		settings = {}

		# Admin account information
		settings['admin'] = {'user': str(admin)}
		settings['admin']['tenant'] = str(tenant)
		settings['admin']['password'] = str(password)
		if not email:
			email = '{user}@{host}'.format(user=settings['admin']['user'], uname()[1])
		settings['admin']['email'] = str(email)

		if not token:
			token = str(check_output('openssl rand -hex 10', shell=True))
		settings['admin']['token'] = str(token)

		# OpenStack settings
		settings['controller'] = str(controller) if controller else uname()[1]
		settings['compute'] = compute if compute and type(compute) is list else [uname()[1]]
		settings['horizon'] = {}
		settings['horizon']['domain'] = str(horizon_domain) if horizon_domain else getfqdn()
		settings['horizon']['https'] = {'enable': bool(enable_https) }
		if bool(enable_https):
			for item, ssl_file in [('crt', ssl_crt), ('key', ssl_key)]:
				settings['horizon']['https'][item] = ssl_file if ssl_file else '/etc/sscloud/ssl/sscloud.%s' % (item)
				if not os.path.isfile(settings['horizon']['https'][item]):
					logger.warning('Missing ssl file: %s, please put file in correct path before you start deployment.' % settings['horizon']['https'][item])

		# The network settings of external interface in Neutron server (default is OpenStack controller node)
		try:
			gw, iface = netifaces.gateways()['defualt'][netifaces.AF_INET]
			network = {'openvswitch': {'br-ex': iface}, iface: [] }
			for _ in netifaces.ifaddresses(iface)[netifaces.AF_INET]:
				ipset = [_['addr'] , _['netmask']]
				ip_network = netaddr.IPNetwork('{ip/netmask}'.format(ip=_['addr'], netmask=_['netmask'])).network
				gw_network = netaddr.IPNetwork('{ip/netmask}'.format(ip=gw, netmask=_['netmask'])).network
				if ip_network == gw_network:
					ipset.append(gw)
				network[iface].append(ipset)
			settings['network_topology'] = { settings['controller']: network }
				
		except Exception, error:
			logger.error('Unknown error: %s', str(error))
		
		with open(self.config, 'w') as f:
			yaml.dump(settings, f)
				

		#with open(self.config, 'w') as f:
		#	config = yaml.load(f)

		#	config.setdefault('openstack': {})
		#	if type(config['openstack']) is not dict:
		#		logger.error('Configuration has wrong format, the value of [openstack] must be dict')
		#		config['openstack'] = {}

		#	config['openstack'].setdefault('admin': {})
		#	if type(config['openstack']['admin']) is not dict:
		#		logger.error('Configuration has wrong format, the value of [openstack][admin] must be dict')
		#		config['openstack']['admin'] = {}

		#	config['openstack']['admin'].setdefault('user', 'admin')
		#	config['openstack']['admin'].setdefault('tenant', 'admin')
		#	config['openstack']['admin'].setdefault('password', 'sscloudadmin')
		#	config['openstack']['admin'].setdefault('email', 'admin@localhost')
		#	config['openstack']['admin'].setdefault('token', check_output('openssl rand -hex 10', shell=True))
		#	config['openstack'].setdefault('controller': uname()[1])
		#	config['openstack'].setdefault('compute': [])
		#	if type(config['openstack']['compute']) is not list:
		#		config['openstack']['compute'] = [uname()[1]]

		
	
