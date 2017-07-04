include_recipe 'delivery-truck::unit'

if (java_changes?(changed_files))

  if (node['delivery']['change']['stage'] == 'verify' && node['delivery']['config']['truck']['update_dependencies']['active'])
    mvn 'bumpDependencies' do
      action :updateDependencies
    end
  end

  mvn 'unit' do
    only_if node['delivery']['config']['truck']['unit']['execute_tests']
    action :unit
  end

#Check Unit Tests
  mvn 'jacoco' do
    only_if node['delivery']['config']['truck']['unit']['execute_tests']
    action :jacoco_report
  end

  if (node['delivery']['config']['truck']['codacy']['upload'] && node['delivery']['change']['stage']=='build')
    remote_file '/tmp/codacy.jar' do
      source node['delivery']['config']['truck']['unit']['codacy_jar']
    end

    execute "java -cp /tmp/codacy.jar com.codacy.CodacyCoverageReporter -l Java -r ./target/site/jacoco/jacoco.xml --projectToken #{node['delivery']['config']['truck']['codacy']['token']}" do
      cwd node['delivery']['workspace']['repo']
    end

  end

#Upload Snapshot
  mvn 'upload' do
    only_if node['delivery']['config']['truck']['maven']['upload_snapshot']
    action :upload
  end

end
