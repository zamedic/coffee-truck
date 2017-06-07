include_recipe 'delivery-truck::functional'


if !node['delivery']['config']['truck']['skip_functional_tests'] && node['delivery']['change']['stage'] != 'delivered'
  mvn 'functional' do
    action :functional
  end
end
