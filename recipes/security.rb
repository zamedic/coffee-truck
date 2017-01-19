include_recipe 'delivery-truck::security'

checkmarx 'update demoncat' do
  action :update_demoncat
end