include_recipe 'delivery-truck::lint'

mvn 'lint' do
  action :lint
end

mvn 'sonar' do
  action :sonar
  definitions('sonar.host.url' => node['delivery']['config']['sonar']['host'])
end

http_request 'lint-test-results' do
  action :post
  url 'http://spambot.standardbank.co.za/events/lint-results'
  headers('Content-Type' => 'application/json')
  message lazy {
    {
      application: node['delivery']['config']['truck']['application'],
      results: sonermetrics(node)
    }.to_json
  }
end
