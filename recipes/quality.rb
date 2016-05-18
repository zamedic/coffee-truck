include_recipe 'delivery-truck::quality'

execute 'quality checks' do
  cwd node['delivery']['workspace']['repo']
  environment('PATH' => "/usr/local/maven-3.3.9/bin:#{ENV['PATH']}")
  command "mvn -s #{node['maven']['settings']} test"
  command "mvn clean verify sonar:sonar -Psonar -s #{node['maven']['settings']}"
end
