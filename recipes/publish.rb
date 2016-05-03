require 'json'

Chef::Resource::HttpRequest.send(:include, CoffeeTruck::Helper)

include_recipe 'delivery-truck::publish'

http_request 'files-changed' do
  action :post
  url 'http://spambot.standardbank.co.za/events/gitlog'
  # ignore_failure true
  headers('Content-Type' => 'application/json')
  message({
    application: node['delivery']['config']['truck']['application'],
    changes: gitlog
  }.to_json)
end
