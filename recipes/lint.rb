include_recipe 'delivery-truck::lint'

mvn 'pmd' do
  action :pmd
end

cookbook_file "/tmp/checkstyle.xml" do
  source 'settings.xml'
  owner 'dbuild'
  group 'root'
  mode 00644
  action :create
end

mvn 'complexity' do
  action :complexity
end

