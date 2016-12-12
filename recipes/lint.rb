include_recipe 'delivery-truck::lint'

mvn 'pmd' do
  action :pmd
end


