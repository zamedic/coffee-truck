include_recipe 'delivery-truck::lint'

mvn 'complexity' do
  action :checkstyle
end

mvn 'pmd' do
  action :pmd
end


