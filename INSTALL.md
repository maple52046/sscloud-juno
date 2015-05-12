# Install

The recommend method to run SSCloud deployment is work with python-virtualenv.


## Install virtualenv

Install packages
```
apt-get install python-virtualenv
```

Then, create a virtualenv
```
cd /opt/sscloud/
virtualenv pyenv
```

### Custom path for virtualenv

If you create virtualenv in another path, you need add a system parameter in current shell env.
```
export VIRTUALENV="/path/to/virtualenv"
```
