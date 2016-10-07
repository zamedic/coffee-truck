default['java']['install_flavor'] = 'oracle'
default['java']['jdk_version'] = '8'
default['java']['oracle']['accept_oracle_download_terms'] = true
default['java']['jdk']['8']['x86_64']['url'] = 'http://plinrepo1v.standardbank.co.za/repo/software/java/jdk-8u60-linux-x64.tar.gz'
default['java']['jdk']['8']['x86_64']['checksum'] = 'ebe51554d2f6c617a4ae8fc9a8742276e65af01bd273e96848b262b3c05424e5'
default['git']['repo'] = nil
default['maven']['settings'] = '/tmp/maven/settings.xml'
default['delivery']['config']['sonar']['host'] = nil
default['delivery']['config']['sonar']['resource'] = nil
default['delivery']['config']['truck']['recipe'] = nil
default['delivery']['config']['truck']['application'] = node['delivery']['change']['project']
default['delivery']['spambot']['publish_unit_results_from_branch'] = false

normal['maven']['3']['version'] = '3.3.9'
normal['maven']['3']['checksum'] = '077ed466455991d5abb4748a1d022e2d2a54dc4d557c723ecbacdc857c61d51b'
