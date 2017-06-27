include_recipe 'delivery-truck::unit'

if (java_changes?(changed_files))

  if(node['delivery']['change']['stage'] == 'verify' && node['delivery']['config']['truck']['update_dependencies']['active'])
    mvn 'bumpDependencies' do
      action :updateDependencies
    end
  end

  mvn 'unit' do
    action :unit
  end

#Check Unit Tests
  mvn 'jacoco' do
    action :jacoco_report
  end

#Upload Snapshot
  if(node['delivery']['config']['truck']['maven']['upload_snapshot'])
    mvn 'upload' do
      action :upload
    end
  end

end
