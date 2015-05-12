#!/usr/bin/env python

# virtualenv setting
execfile('setvenv', dict(__file__='setvenv'))

import apt
import logging
import netifaces
import subprocess

from platform import uname

logger = logging.getLogger(__name__)

def check_or_install(install=False, skip_apt_update=True):
	"""
	This function is used to install or check package "openvswitch-switch"
	"""
	assert isinstance(install, bool)
	assert isinstance(skip_apt_update, bool)

	apt_cache = apt.cache.Cache()
	if not skip_apt_update:
		apt_cache.update()

	pkg = apt_cache['openvswitch-switch']
	if pkg.is_installed:
		if install:
			logger.debug('Package openvswitch-switch is installed')
		install = True
	else:
		if install:
			try:
				pkg.mark_install()
				apt_cache.commit()
				logger.debug('Successfully install packages(openvswitch-switch)')
			except Exception, err:
				logger.error('Failed to install Open vSwitch, error message: %s', str(err))
				install = False

	return install

def migrate_ip(before, target, ip ,netmask, only_remove=False):
	"""
	This function is used to migrate IP address from an interface to another;
	It's also can be used to remove IP address from an interface and not migrate IP address.
	"""
	assert isinstance(before, str)
	assert isinstance(target, str)
	assert isinstance(ip, str)
	assert isinstance(netmask, str)
	assert isinstance(only_remove, bool)

	if not only_remove:
		# If target IP and gateway IP is under same network CIDR,
		# remove IP from interface maybe let gateway setting is gone.
		# So, save gateway setting and check it again after migate IP is finished.
		try:
			gw, dev = netifaces.gateways()['default'][netifaces.AF_INET]
		except:
			# No need to check gateway setting if gateway is not exist.
			gw = None

	# Remove IP from interface
	try:
		cmd = "ip addr del %s/%s dev %s" % (ip, netmask, before)
		subprocess.check_call(cmd, shell=True)
	except Exception, err:
		logger.error("Failed to remove IP(%s) from interface(%s): %s", ip, before, str(err))
		return False

	if not only_remove:
		# Add IP to interface
		try:
			cmd = "ip addr add %s/%s dev %s" % (ip, netmask, target)
			subprocess.check_call(cmd, shell=True)
		except Exception, err:
			logger.error("Failed to add IP(%s) to interface(%s): %s", ip, target, str(err))
			return False

		# Check gateway setting again
		if gw:
			try:
				netifaces.gateways()['default'][netifaces.AF_INET]
			except:
				try:
					cmd = 'route add default gw %s' % gw
					subprocess.check_call(cmd, shell=True)
				except Exception, err:
					logger.error("Failed recover gateway setting: %s", str(err))
					return False

	return True

class ovs:
	def __init__(self):
		self.pkgexist = check_or_install()

	def install(self,skip_apt_update=False):
		"""
		Install Open vSwitch package
		"""
		assert isinstance(skip_apt_update, bool)
		self.pkgexist = check_or_install(True, skip_apt_update)
		return self.pkgexist

	def addbr(self, ovs, ports=[], dhcp=False):
		"""
		Create ovs bridge
		"""
		assert isinstance(ovs, str)
		assert isinstance(ports, list)
		assert isinstance(dhcp, bool)

		# Check package openvswitch-switch
		if not self.pkgexist:
			logger.error('Open vSwitch package does not exist.')
			return False

		# Check argument type
		assert isinstance(ovs, str)

		# Create ovs
		try:
			cmd = 'ovs-vsctl --may-exist add-br %s' % ovs
			subprocess.check_call(cmd, shell=True)
			logger.debug("Successfully create ovs bridge: %s", ovs)
		except Exception, err:
			try:
				cmd = 'ovs-vstl list-br'
				subprocess.check_output(cmd, shell=True).split('\n').index(ovs)
				logger.warning('OVS bridge(%s) is exist.', ovs)
			except:
				logger.error("Create ovs bridge(%s) has error: %s", ovs, str(err))
				return False

		# Add port to ovs
		if ports:
			return self.addport(ovs, ports, dhcp)
		elif dhcp:
			return self.dhcp(ovs)

		return True

	def addport(self, ovs, ports=[], dhcp=False):
		"""
		Add an interface to ovs
		"""
		assert isinstance(ovs, str)
		assert isinstance(ports, list)
		assert isinstance(dhcp, bool)

		# Startup ovs bridge
		try:
			cmd = 'ifconfig %s up' % ovs
			subprocess.check_call(cmd, shell=True)
		except Exception, err:
			logger.error("Failed to startup ovs bridge: %s, error message: %s'", ovs, str(err))
			return False

		for port in ports:
			# Add port and set promisc mode
			if port in netifaces.interfaces():
				try:
					cmd = 'ovs-vsctl --may-exist add-port %s %s' % (ovs, port)
					subprocess.check_call(cmd, shell=True)
					logger.debug("Successfully add port(%s) to ovs(%s)", port, ovs)
					cmd = 'ip link set %s promisc on' % port
					subprocess.check_call(cmd, shell=True)
					logger.debug("Trun on promisc mode on the interface(%s)", port)
				except Exception, err:
					try:
						# Check port exist or not
						cmd = 'ovs-vsctl list-ports %s' % ovs
						subprocess.check_output(cmd, shell=True).split('\n').index(port)
						logger.warning("OVS port(%s) is exist on ovs(%s)", port, ovs)
					except:
						logger.error("Add ovs port(ovs: %s, port: %s) has error: %s", ovs, port, str(err))
						ports.remove(port)
						logger.warning("Remove %s from ports list", port)
			else:
				logger.error("Interface(%s) does not exist on system", port)
				ports.remove(port)
				logger.warning("Remove %s from ports list", port)

		if dhcp:
			for port in ports:
				self.mac_mapping(ovs, port)
				try:
					dhcp = self.dhcp(ovs)
				except KeyboardInterrupt:
					logger.warning("Interrupt DHCP client by user, try next mac address.")
				else:
					if dhcp:
						break

		for port in ports:
			# Migrate IP from port to ovs
			try:
				for _ in netifaces.ifaddresses(port)[netifaces.AF_INET]:
					# If dhcp is True, mean ovs is be configed by DCHP,
					# then we just need to remove IP from ovs port.
					migrate_ip(port, ovs, _['addr'], _['netmask'], dhcp)
			except:
				pass

		return True

	def dhcp(self, iface):
		"""
		Configure interface by DHCP
		"""
		assert isinstance(iface, str)
		try:
			cmd = 'dhclient -v %s' % iface
			logger.debug("Start DHCP client on %s, you can interrupt this action by 'Ctrl+C'", iface)
			subprocess.check_call(cmd, shell=True)
			logger.debug("Configure insterface(%s) by DHCP", iface)
		except Exception, err:
			logger.error("Failed to get DHCP IP on interface(%s): %s", iface, str(err))
			return False

		return True

	def mac_mapping(self, ovs, port):
		"""
		Mapping mac address of ovs and ovs port
		"""
		assert isinstance(ovs, str)
		assert isinstance(port, str)

		mac = netifaces.ifaddresses(port)[netifaces.AF_LINK][-1]['addr']

		try:
			cmd = 'ovs-vsctl set bridge %s other-config:hwaddr=%s' % (ovs, mac)
			subprocess.check_call(cmd, shell=True)
			logger.debug("Set macaddr(%s) for ovs bridge(%s)", mac, ovs)
		except Exception, err:
			logger.error("Set macaddr(%s) for ovs bridge(%s) has error: %s", mac, ovs, str(err))
			return False

		return True

if __name__ == "__main__":
	import argparse
	import sys

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
	parser.add_argument('ovs', nargs=1, help="name of ovs")
	parser.add_argument('interfaces', nargs='*', help="interface name to addport to ovs")
	parser.add_argument('--dhcp', action="store_true", default=False, help="configure ovs by DHCP")
	args = parser.parse_args()

	obj = ovs()
	obj.addbr(args.ovs[0], args.interfaces, args.dhcp)
