include_recipe 'delivery-truck::lint'

if (java_changes?(changed_files))
  mvn 'compile' do
    action :compile
  end

  if (node['delivery']['config']['truck']['lint']['execute_findbugs'])
    mvn 'find_bugs' do
      action :findbugs
    end
  end
end