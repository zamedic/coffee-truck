include_recipe 'delivery-truck::lint'

mvn 'pmd' do
  action :pmd
end

http_request 'sonar-results' do
  action :post
  url 'http://spambot.standardbank.co.za/events/lint-results'
  ignore_failure true
  headers('Content-Type' => 'application/json')
  message lazy {
    {
        application: node['delivery']['config']['truck']['application'],
        results: {
            issues: count_pmd_violations(node)
        }
    }.to_json
  }
end
