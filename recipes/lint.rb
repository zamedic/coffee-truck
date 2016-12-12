include_recipe 'delivery-truck::lint'

mvn 'complexity' do
  action :checkstyle
end

Chef::Log.error(current_complexity(node))

http_request 'complexity-results' do
  action :post
  url 'http://spambot.standardbank.co.za/events/lint-results'
  ignore_failure true
  headers('Content-Type' => 'application/json')
  message lazy {
    {
        application: node['delivery']['config']['truck']['application'],
        complexity: current_complexity(node)
    }.to_json
  }
end

mvn 'pmd' do
  action :pmd
end


