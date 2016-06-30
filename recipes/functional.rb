include_recipe 'delivery-truck::functional'


unless node['delivery']['change']['stage'] == 'delivered'
  mvn 'functional' do
    action :functional
  end
end
