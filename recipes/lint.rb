include_recipe 'delivery-truck::lint'

mvn 'compile' do
  action :compile
end

mvn 'complexity' do
  action :checkstyle
end



mvn 'pmd' do
  action :pmd
end


