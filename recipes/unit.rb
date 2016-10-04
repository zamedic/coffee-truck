mvn 'unit' do
  action :unit
end


mvn 'sonar' do
  action :sonar
  definitions('sonar.host.url' => node['delivery']['config']['sonar']['host'])
end

http_request 'sonar-results' do
  action :post
  url 'http://spambot.standardbank.co.za/events/test-results'
  # ignore_failure true
  headers('Content-Type' => 'application/json')
  message({
    application: node['delivery']['change']['project'],
    results: sonarmetrics(node)
  }.to_json)
end

#Upload Snapshot
mvn 'upload' do
  action :upload
end
