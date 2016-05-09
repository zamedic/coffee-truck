#execute 'unit tests' do
#  cwd node['delivery']['workspace']['repo']
#  environment('PATH' => "/usr/local/maven-3.3.9/bin:#{ENV['PATH']}")
#  command "mvn clean verify -s #{node['maven']['settings']} -Dsonar.host.url=#{node['delivery']['config']['sonar']['host']} -Psonar --fail-at-end"
#end

mvn 'unit' do
  action :unit
  cwd node['delivery']['workspace']['repo']
  environment('PATH' => "/usr/local/maven-3.3.9/bin:#{ENV['PATH']}")
  settings node['maven']['settings']
  definitions('sonar.host.url' => node['delivery']['config']['sonar']['host'])
end


execute 'unit tests' do
  cwd node['delivery']['workspace']['repo']
  environment('PATH' => "/usr/local/maven-3.3.9/bin:#{ENV['PATH']}")
  command "mvn -s #{node['maven']['settings']} -Dsonar.host.url=#{node['delivery']['config']['sonar']['host']} sonar:sonar"
end

http_request 'sonar-results' do
  action :post
  url 'http://spambot.standardbank.co.za/events/sonar'
  # ignore_failure true
  headers('Content-Type' => 'application/json')
  message({
    application: node['delivery']['config']['truck']['application'],
    results: sonarmetrics(node)
  }.to_json)
end
