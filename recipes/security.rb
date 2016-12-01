include_recipe 'delivery-truck::security'

mvn 'security' do
  action :security
end

mvn 'sonar' do
  action :sonar
  definitions('sonar.host.url' => node['delivery']['config']['sonar']['host'])
end

http_request 'security-test-results' do
  action :post
  url 'http://spambot.standardbank.co.za/events/security-results'
  headers('Content-Type' => 'application/json')
  message lazy {
    {
      application: node['delivery']['config']['truck']['application'],
      results: sonermetrics(node)
    }.to_json
  }
end

