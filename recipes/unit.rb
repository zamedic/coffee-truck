mvn 'unit' do
  action :unit
end

mvn 'jacoco' do
  action :jacoco_report
end

http_request 'sonar-results' do
  ignore_failure true
  action :post
  url 'http://spambot.standardbank.co.za/events/test-results'
  headers('Content-Type' => 'application/json')
  message lazy {
    {
      application: node['delivery']['config']['truck']['application'],
      results: sonarmetrics(node)
    }.to_json
  }
end

#Upload Snapshot
mvn 'upload' do
  action :upload
end
