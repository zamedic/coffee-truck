include_recipe 'delivery-truck::publish'

mvn 'release_prepare' do
  action :release_prepare
end

mvn 'release_perform  ' do
  action :release_perform
end









