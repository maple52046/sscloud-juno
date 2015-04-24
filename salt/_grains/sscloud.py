from keystoneclient.v2_0 import client
import yaml

try:
    config = yaml.load(file('/etc/sscloud/config.yml','r'))
    token = config['keystone']['token']
    endpoint = config['keystone']['endpoint']['admin']
    keystone = client.Client(token=token, endpoint=endpoint) 
except:
    pass

def sscloud_information():

    # Admin Role ID for SSID consumer
    admin = {'role_id': ''}
    try:
        for role in keystone.roles.list():
            if role.name == 'admin':
                admin['role_id'] = str(role.id)
                break
    except:
        pass

    # Get Nova Tenant ID for OpenStack Neutron configuration
    nova_tenant_name = 'service'
    tenants = keystone.tenants.list()
    nova = {'tenant_id': ''}
    try:
        for tenant in tenants:
            if str(tenant.name) == nova_tenant_name:
                nova['tenant_id'] = str(tenant.id)
                break
    except:
        pass

    # Return Grains
    return {'sscloud':{'admin':admin, 'nova':nova}}
