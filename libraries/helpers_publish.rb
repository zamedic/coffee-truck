module CoffeeTruck
  module Helpers
    module Publish
      extend self

      def gitlog(node)
        cwd = node['delivery']['workspace']['repo']
        command = 'git log --numstat --pretty="%H" --since="1 month ago" | awk \'NF==3 {a[$3]+=$1+$2} END {for (i in a) printf("%5d\t%s\n", a[i], i)}\' | grep .java$ | sort -k1 -rn'
        log = `cd #{cwd} && #{command}`
        log.split("\n").map { |line| line.strip.split("\t").reverse }.to_h
      end

      def sync_envs(app_name)
        change = node['delivery']['change']
        parts = %w(enterprise organization project pipeline)
        env_parts = parts.map{|part| change[part]}.join('-')
        Chef::Log.error("PARTS: #{env_parts}")
        acceptance_environment = "acceptance-#{env_parts}"
        current_env = load_chef_environment(acceptance_environment)
        app_version = current_env.override_attributes['applications'][app_name]
        search_query = "recipes:#{node['delivery']['config']['truck']['recipe']} " \
                 "AND chef_environment:acceptance-*"
        my_nodes = delivery_chef_server_search(:node, search_query)
        my_nodes.each do |node|
          cookbook_env = load_chef_environment(node[:chef_environment])
          cookbook_env.override_attributes['applications'][app_name] = app_version
          save_chef_environment(env)
        end
      end
    end
  end

  module DSL

    def gitlog(node)
      CoffeeTruck::Helpers::Publish.gitlog(node)
    end

    def sync_envs(app_name)
      CoffeeTruck::Helpers::Publish.sync_envs(app_name)
    end
  end
end
