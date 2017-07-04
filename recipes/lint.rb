include_recipe 'delivery-truck::lint'

if (java_changes?(changed_files))
  mvn 'compile' do
    action :compile
  end

  mvn 'find_bugs' do
    only_if node['delivery']['config']['truck']['lint']['execute_findbugs']
    action :findbugs
  end
end