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


      def load_chef_environment(env_name)
        chef_server.with_server_config do
          Chef::Environment.load(env_name)
        end
      end

      def save_chef_environment(env)
        chef_server.with_server_config do
          env.save
        end
      end

      def chef_server
        DeliverySugar::ChefServer.new
      end

      def delivery_chef_server_search(type, query)
        results = []
        chef_server.with_server_config do
          ::Chef::Search::Query.new.search(type, query) { |o| results << o } 
        end 
        results
      end 

      def sync_envs(node,version)
        Chef::Log.warn("setting version of #{node['delivery']['change']['project']} to #{version}")
      end
    end
  end

  module DSL

    def gitlog(node)
      CoffeeTruck::Helpers::Publish.gitlog(node)
    end

    def sync_envs(node,version)
      CoffeeTruck::Helpers::Publish.sync_envs(node,version)
    end
  end
end
