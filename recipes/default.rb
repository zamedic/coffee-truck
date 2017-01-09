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

hostsfile_entry '127.0.0.2' do
  hostname 'accstandardbank.d1.sc.omtrdc.net'
  aliases ['lar.standardbank.co.za','rwp.standardbank.co.za','cdn.standardbank.co.za','dfib.standardbank.co.za','dspk.standardbank.co.za','trk.standardbank.co.za']
  action :create
end

directory '/tmp/geckodriver' do
  action :create
  recursive true
end

remote_file 'gecko driver' do
  source 'http://plinrepo1v.standardbank.co.za/repo/software/selenium/geckodriver-v0.12.0-linux64.tar.gz'
  path '/tmp/geckodriver/geckodriver.tar.gz'
end

execute 'untar gecko' do
  action :run
  command 'tar -xvzf geckodriver.tar.gz'
  cwd '/tmp/geckodriver'
end

file "/usr/bin/geckodriver" do
  owner 'root'
  group 'root'
  mode 0755
  content lazy {::File.open("/tmp/geckodriver/geckodriver").read }
  action :create
end

package 'firefox'
package 'Xvfb'

execute 'start_xvfb' do
  command 'Xvfb :10 -ac &'
end