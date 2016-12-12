mvn 'release_prepare' do
  action :release_prepare
end

mvn 'release_perform  ' do
  action :release_perform
end


include_recipe 'delivery-truck::publish'

http_request 'files-changed' do
  action :post
  url 'http://spambot.standardbank.co.za/events/gitlog'
  ignore_failure true
  headers('Content-Type' => 'application/json')
  message lazy {
    {
      application: node['delivery']['config']['truck']['application'],
      changes: gitlog(node)
    }.to_json
  }
end

http_request 'test-results' do
  action :post
  url 'http://spambot.standardbank.co.za/events/test-results'
  ignore_failure true
  headers('Content-Type' => 'application/json')
  message lazy {
    {
      application: node['delivery']['config']['truck']['application'],
      results: sonarmetrics(node)
    }.to_json
  }
end

http_request 'lint-results' do
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

http_request 'complexity-results' do
  action :post
  url 'http://spambot.standardbank.co.za/events/quality-results'
  ignore_failure true
  headers('Content-Type' => 'application/json')
  message lazy {
    {
        application: node['delivery']['config']['truck']['application'],
        results: current_complexity(node)
    }.to_json
  }
end



