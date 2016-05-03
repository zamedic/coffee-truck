# include_recipe 'sbgtest::setup'
# include_recipe 'sbgtest::install'

search_query = "(recipes:#{node['truck']['recipe']}*) " \
                 "AND chef_environment:#{delivery_environment} " \
                 "AND recipes:push-jobs*"

my_nodes = delivery_chef_server_search(:node, search_query)

my_nodes.map!(&:fqdn)

my_nodes.each do |fqdn|
  execute 'acceptance tests' do
    cwd node['delivery']['workspace']['repo']
    environment('PATH' => "/usr/local/maven-3.3.9/bin:#{ENV['PATH']}")
    command "mvn clean verify -Dhost=#{fqdn} -Pacceptance-tests -s #{node['maven']['settings']}"
  end
end
