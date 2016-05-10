search_query = "recipes:#{node['delivery']['config']['truck']['recipe']} " \
               "AND chef_environment:#{delivery_environment} " \
               "AND #{deployment_search_query}"

Chef::Log.error(search_query)
my_nodes = delivery_chef_server_search(:node, search_query)
Chef::Log.error(my_nodes)

my_nodes.map!(&:name)
Chef::Log.error(my_nodes.join(", "))

delivery_push_job "deploy_#{node['delivery']['change']['project']}" do
  command 'chef-client'
  nodes my_nodes
end


ruby_block 'blarg' do
  block do
    raise RuntimeError, 'blarg'
  end
end
