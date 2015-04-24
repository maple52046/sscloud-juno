#!/opt/sscloud/bin/python

import logging
import os
import yaml

from jinja2 import Template
from platform import uname
from shutil import move
from subprocess import check_output

logger = logging.getLogger(__main__)

class configs:
	def __init__(self, config='/etc/sscloud/config.yml'):
		self.config = config

	def genconfig(self, admin, tenant, password, email=None, token=None):
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
		settings['admin'] = {'user': str(admin)}
		settings['admin']['tenant'] = str(tenant)
		settings['admin']['password'] = str(password)
		if not email:
			email = '{user}@{host}'.format(user=settings['admin']['user'], uname()[1])
		settings['admin']['email'] = str(email)

		if not token:
			token = str(check_output('openssl rand -hex 10', shell=True))
		settings['admin']['token'] = str(token)


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

		
	
