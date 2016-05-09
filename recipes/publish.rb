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

mvn 'upload' do
  action :upload
  cwd node['delivery']['workspace']['repo']
  environment('PATH' => "/usr/local/maven-3.3.9/bin:#{ENV['PATH']}")
  settings node['maven']['settings']
  definitions('skipITs' => nil)
end

raise RuntimeError 'Stop the bus!'
