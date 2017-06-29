include_recipe 'delivery-truck::unit'

if (java_changes?(changed_files))

  if (node['delivery']['change']['stage'] == 'verify' && node['delivery']['config']['truck']['update_dependencies']['active'])
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

  if (node['delivery']['config']['truck']['codacy']['upload'] && node['delivery']['change']['stage']=='build')
    remote_file '/tmp/codacy.jar' do
      source 'https://github.com/codacy/codacy-coverage-reporter/releases/download/2.0.0/codacy-coverage-reporter-2.0.0-assembly.jar'
    end

    execute "java -cp /tmp/codacy.jar com.codacy.CodacyCoverageReporter -l Java -r ./target/site/jacoco/jacoco.xml --projectToken #{node['delivery']['config']['truck']['codacy']['token']}" do
      cwd node['delivery']['workspace']['repo']
    end

  end

#Upload Snapshot
  if (node['delivery']['config']['truck']['maven']['upload_snapshot'])
    mvn 'upload' do
      action :upload
    end
  end

end
