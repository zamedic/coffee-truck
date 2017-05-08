default['coffee-truck']['install-maven'] = true
default['coffee-truck']['install-java'] = true

default['coffee-truck']['functional']['selenium'] = true
default['coffee-truck']['functional']['gecko-driver'] = 'https://github.com/mozilla/geckodriver/releases/download/v0.15.0/geckodriver-v0.15.0-linux64.tar.gz'

default['coffee-truck']['security']['checkmarx']['address'] = nil
default['coffee-truck']['security']['checkmarx']['port'] = nil
default['coffee-truck']['security']['checkmarx']['key'] = nil

default['java']['install_flavor'] = 'oracle'
default['java']['jdk_version'] = '8'
default['java']['oracle']['accept_oracle_download_terms'] = true


default['maven']['settings'] = nil

default['delivery']['config']['truck']['application'] = node['delivery']['change']['project']

normal['maven']['3']['version'] = '3.3.9'
normal['maven']['3']['checksum'] = '077ed466455991d5abb4748a1d022e2d2a54dc4d557c723ecbacdc857c61d51b'
