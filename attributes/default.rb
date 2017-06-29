default['coffee-truck']['install-maven'] = true
default['coffee-truck']['install-java'] = true

default['coffee-truck']['functional']['selenium'] = true
default['coffee-truck']['functional']['gecko-driver'] = 'https://github.com/mozilla/geckodriver/releases/download/v0.15.0/geckodriver-v0.15.0-linux64.tar.gz'

default['coffee-truck']['security']['checkmarx']['address'] = nil
default['coffee-truck']['security']['checkmarx']['port'] = nil
default['coffee-truck']['security']['checkmarx']['key'] = nil

default['coffee-truck']['maven']['settings'] = nil

default['delivery']['config']['truck']['application'] = node['delivery']['change']['project']

default['coffee-truck']['release']['user'] = ''
default['coffee-truck']['release']['email'] = ''
default['delivery']['config']['truck']['update_dependencies']['include'] = nil
default['delivery']['config']['truck']['update_dependencies']['active'] =false
default['delivery']['config']['truck']['maven']['upload_snapshot'] = false

default['delivery']['config']['truck']['codacy']['upload'] = false
default['delivery']['config']['truck']['codacy']['token'] = nil

default['maven']['setup_bin'] = true
default['java']['jdk_version'] = 8