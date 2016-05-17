include_recipe 'delivery-test::default'
include_recipe 'maven-wrapper::default'

directory '/tmp/maven' do
  owner 'dbuild'
  group 'root'
  mode '0755'
  action :create
end

cookbook_file node['maven']['settings'] do
  source 'settings.xml'
  owner 'dbuild'
  group 'root'
  mode 00644
  action :create
end
