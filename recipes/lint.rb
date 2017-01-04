include_recipe 'delivery-truck::lint'

mvn 'compile' do
  action :compile
end

mvn 'checkstyle' do
  action :checkstyle
end

mvn 'pmd' do
  action :pmd
end


