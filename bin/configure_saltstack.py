#!/opt/sscloud/bin/python

import apt
import logging
import os
import subprocess
import yaml

from jinja2 import Environment, FileSystemLoader
from platform import uname
from shutil import move

logger = logging.getLogger(__name__)

class salt:
	def __init__(self):
		self._master = None
		self.host = uname()[1]

	@property
	def master(self):
		return self._master

	@master.setter
	def master(self, hostname):
		self._master = str(hostname)
		logger.debug('Set master node is %s', hostname)
		return True

	def config(self, sscloud_config='/etc/sscloud/config.yml'):
		"""
		Generate configuration for Salstack by setting from SSCloud configuration.
		The controller of SSCloud will be master node of Saltstack;
		And the compute node of SSCloud will be minion of Salstack.

		If you want to use custom master node,
		you must call master() function before config() function.
		"""

		# Get settings from sscloud configuration
		with open(sscloud_config, 'r') as f:
			sscloud = yaml.load(f)

		settings = dict()
		# Set master
		if not self.master:
			self.master = sscloud['openstack']['controller']

		if self.host == self.master:
			settings['config'] = sscloud_config
			logger.debug('Generate master configuration for saltstack')
			self.genconfig('/etc/salt/master', '/opt/sscloud/templates/salt/master', settings)
		else:
			logger.debug('This host(%s) is not master(%s)', self.host, self.master)

		# Set minion
		# Get keystone settings
		try:
			settings['token'] = sscloud['keystone']['token']
		except:
			settings['token'] = sscloud['openstack']['admin']['token']

		try:
			settings['endpoint'] = sscloud['keystone']['endpoint']['admin']
		except:
			settings['endpoint'] = 'http://%s:35357/v2.0' % sscloud['openstack']['controller']

		settings['master'] = self.master
		settings['minion'] = self.host
		logger.debug('Generate minion configuration for saltstack')
		self.genconfig('/etc/salt/minion', '/opt/sscloud/templates/salt/minion', settings)
		logger.debug('Generate keystone configuration for saltstack minion')
		self.genconfig('/etc/salt/minion.d/keystone.conf', '/opt/sscloud/templates/salt/minion.d/keystone.conf', settings)

		return True

	def genconfig(self, path='/etc/salt/minion', template='/opt/sscloud/templates/salt/minion', settings=dict()):
		"""
		Generate saltstack configuration.

		* Master:
			- path: /etc/salt/master
			- template: /opt/sscloud/templates/salt/master

		* Minion:
			- path: /etc/salt/minion
			- template: /opt/sscloud/templates/salt/minion
			- settings: {'master': '<master name>', 'minion': '<minion name>'}

		* Keystone setting for minion:
			- path: /etc/salt/minion.d/keystone.conf
			- template: /opt/sscloud/templates/salt/minion.d/keystone.conf
			- settings: {'token': '<keystone token>', 'endpoint': '<keystone endpoint>'}
		"""
		# Get template
		if os.path.isfile(template):
			env = Environment(loader=FileSystemLoader(os.path.dirname(template)))
			temp = env.get_template(os.path.basename(template))
		else:
			logger.error('Tempalte(%s) not exist.', template)
			return False

		# Create directory
		if not os.path.exists(os.path.dirname(path)):
			os.makedirs(os.path.dirname(path))

		# Generate configuration
		if os.path.isfile(path):
			backup = os.path.dirname(path) + '/.' + os.path.basename(path) + '.bak'
			move(path, backup)
			logger.warning('Target file({0}) is exist. Move to {1}'.format(path, backup))

		with open(path, 'w') as f:
			f.write(temp.render(settings=settings))

		return True

	def install(self):
		"""
		Install saltstack.
		"""
		
		apt_cache = apt.cache.Cache()
		logger.debug('Updating cache of apt-get')
		apt_cache.update()

		# Install packages
		services = ['salt-minion']
		if self.host == self.master:
			services.append('salt-master')
	
		for _ in services:
			pkg = apt_cache[ _ ]
			if pkg.is_installed:
				logger.debug('Package: %s is installed.', _ )
			else:
				pkg.mark_install()

		# Install packages
		try:
			apt_cache.commit()
		except Exception, error:
			logger.error('Failed to install packages, the error message: %s', str(error))
			return False

		return True

	def service(self, start=True, stop=False):
		"""
		Start or stop saltstack service (master and minion)
		If both start and stop is True, function will stop all service then start them.
		"""

		if stop:
			services = ['salt-minion']
			if self.host == self.master:
				services.append('salt-master')

			for ps in services:
				try:
					cmd = 'ps -e | grep %s' % ps
					subprocess.check_call(cmd, shell=True)

					logger.debug('Shutdown %s', ps)
					cmd = 'service %s stop' % ps
					subprocess.check_call(cmd, shell=True)

					cmd = 'killall %s' % ps
					subprocess.check_call(cmd, shell=True)
				except:
					pass

		if start:
			services = ['salt-minion']
			if self.host == self.master:
				services.insert(0, 'salt-master')

			for ps in services:
				try:
					cmd = 'ps -e | grep %s' % ps
					subprocess.check_call(cmd, shell=True)
					logger.error('%s process is running, pleae stop service before start', ps)
					return False
				except:
					try:
						cmd = 'service %s start' % ps
						subprocess.check_call(cmd, shell=True)
						logger.debug('Start %s', ps)
					except Exception, error:
						logger.error('Start %s has error message: %s', ps, str(error))
						return False

		return True

if __name__ == "__main__":
	import argparse

	try:
		import coloredlogs
		coloredlogs.install(level=logging.DEBUG)
	except:
		# Log
		formatter = logging.Formatter('%(asctime)s [%(levelname)s] %(message)s')
		root = logging.getLogger()
		root.setLevel(logging.DEBUG)
		ch = logging.StreamHandler()
		ch.setLevel(logging.DEBUG)
		ch.setFormatter(formatter)
		root.addHandler(ch)

	# Args
	parser = argparse.ArgumentParser()

	parser.add_argument('-m', '--master', help="saltstack master")
	parser.add_argument('-c', '--config', help="sscloud conifguration")

	args = parser.parse_args()

	# Main
	obj = salt()
	if args.master:
		obj.master = args.master

	if args.config:
		obj.config(args.config)
	else:
		obj.config()

	obj.install()
	obj.service(start=True, stop=True)

