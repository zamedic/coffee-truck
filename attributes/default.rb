default['coffee-truck']['install-maven'] = true
default['coffee-truck']['install-java'] = true

default['coffee-truck']['functional']['selenium'] = true
default['coffee-truck']['functional']['gecko-driver'] = 'https://github.com/mozilla/geckodriver/releases/download/v0.15.0/geckodriver-v0.15.0-linux64.tar.gz'

default['coffee-truck']['security']['checkmarx']['address'] = nil
default['coffee-truck']['security']['checkmarx']['port'] = nil
default['coffee-truck']['security']['checkmarx']['key'] = nil

default['delivery']['config']['truck']['unit']['execute_tests'] = true
default['delivery']['config']['truck']['unit']['codacy_jar'] = 'https://github.com/codacy/codacy-coverage-reporter/releases/download/2.0.0/codacy-coverage-reporter-2.0.0-assembly.jar'
default['delivery']['config']['truck']['syntax']['execute_pmd'] = true
default['delivery']['config']['truck']['syntax']['execute_checkstyle'] = true
default['delivery']['config']['truck']['lint']['execute_findbugs'] = true

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