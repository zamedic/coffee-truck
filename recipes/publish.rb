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
  # ignore_failure true
  headers('Content-Type' => 'application/json')
  message({
    application: node['delivery']['config']['truck']['application'],
    changes: gitlog(node)
  }.to_json)
end

