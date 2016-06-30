current_env = delivery_environment
current_env = 'acceptance-*' if current_env.start_with? 'acceptance-'

search_query = "recipes:#{node['delivery']['config']['truck']['recipe']} " \
               "AND chef_environment:#{current_env} " \
               "AND #{deployment_search_query}"

my_nodes = delivery_chef_server_search(:node, search_query)
my_nodes.map!(&:name)

delivery_push_job "deploy_#{node['delivery']['change']['project']}" do
  command 'chef-client'
  nodes my_nodes
end
