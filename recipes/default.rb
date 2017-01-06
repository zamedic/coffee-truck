include_recipe 'delivery-truck::default'
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

cookbook_file "/tmp/checkstyle.xml" do
  source 'checkstyle-checker.xml'
  owner 'dbuild'
  group 'root'
  mode 00644
  action :create
end

hostsfile_entry '10.145.31.31' do
  hostname  'sonar.k8s.standardbank.co.za'
  unique    true
end

hostfile_entry '127.0.0.1' do
  hostname 'accstandardbank.d1.sc.omtrdc.net'
  aliases ['lar.standardbank.co.za','rwp.standardbank.co.za','cdn.standardbank.co.za','dfib.standardbank.co.za','dspk.standardbank.co.za','trk.standardbank.co.za']
  action :create
end



package 'firefox'
package 'Xvfb'