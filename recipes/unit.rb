Chef::Log.error("=======\n#{node['truck']['application']}\n========")

execute 'unit tests' do
  cwd node['delivery']['workspace']['repo']
  environment('PATH' => "/usr/local/maven-3.3.9/bin:#{ENV['PATH']}")
  command "mvn clean verify -s #{node['maven']['settings']} -Dsonar.host.url=#{node['sonar']['host']} -Psonar --fail-at-end"
end


execute 'unit tests' do
  cwd node['delivery']['workspace']['repo']
  environment('PATH' => "/usr/local/maven-3.3.9/bin:#{ENV['PATH']}")
  command "mvn -s #{node['maven']['settings']} -Dsonar.host.url=#{node['sonar']['host']} sonar:sonar"
end
