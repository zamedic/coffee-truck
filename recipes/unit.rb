execute 'unit tests' do
  cwd node['delivery']['workspace']['repo']
  environment('PATH' => "/usr/local/maven-3.3.9/bin:#{ENV['PATH']}")
  command "mvn clean verify -s #{node['maven']['settings']} -Dsonar.host.url=http://dchop169.standardbank.co.za:9000/ -Psonar --fail-at-end"
end


execute 'unit tests' do
  cwd node['delivery']['workspace']['repo']
  environment('PATH' => "/usr/local/maven-3.3.9/bin:#{ENV['PATH']}")
  command "mvn -s #{node['maven']['settings']} -Dsonar.host.url=http://dchop169.standardbank.co.za:9000/ sonar:sonar"
end
