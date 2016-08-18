

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

#Upload Snapshot
mvn 'upload' do
  action :upload
end
