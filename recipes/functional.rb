include_recipe 'delivery-truck::functional'

unless node['delivery']['change']['stage'] == 'delivered'



  execute 'start_xvfb' do
    command 'Xvfb :10 -ac &'
  end

  mvn 'functional' do
    action :functional
  end


end
