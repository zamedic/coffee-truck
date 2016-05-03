require 'json'

Chef::Resource::HttpRequest.send(:include, SbgTruck::Helper)

include_recipe 'delivery-truck::publish'

http_request 'files-changed' do
  action :post
  url 'http://spambot.standardbank.co.za/events/gitlog'
  # ignore_failure true
  headers('Content-Type' => 'application/json')
  message({
    application: 'SBG1',
    description: 'SBG Platform',
    changes: gitlog
  }.to_json)
end
