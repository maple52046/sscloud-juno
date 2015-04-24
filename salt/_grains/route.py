from subprocess import check_output

def gateway():
	output = check_output('route -n | grep ^0.0.0.0', shell=True).split()
	return {'route': {'gateway': output[1], 'interface': output[7]} }
