require 'chef/mixin/shell_out'
require 'nokogiri'


module CoffeeTruck
  module Helpers
    module Lint
      include Chef::Mixin::ShellOut
      extend self

      PMD_VIOLATIONS = 'violations'
      BUGS = 'bugs'
      CHECKSTYLE = 'checkstyle'

      def count_pmd_violations(node)
        file = "#{node['delivery']['workspace']['repo']}/target/pmd.xml"
        doc = ::File.open(file) { |f| Nokogiri::XML(f) }
        doc.xpath("count(//violation)").to_i
      end

      def check_pmd?(node)
        current = count_pmd_violations(node)
        previous = previous_pmd_violations(node)

        if (current > previous.to_i)
          raise RuntimeError, "PMD violations increased from #{previous} to #{current}. Failing Build"
        end
        Chef::Log.warn("Projects previous PMD violations #{previous}, new PMD violations  #{current}.")
      end

      def previous_pmd_violations(node)
        chef_server.with_server_config do
          begin
            databag_item = Chef::DataBagItem.load('delivery', node['delivery']['config']['truck']['application'])
            return databag_item.raw_data[PMD_VIOLATIONS] ? databag_item.raw_data[PMD_VIOLATIONS] : 99999
          rescue Net::HTTPServerException
            Chef::Log.warn("No Databag with complexity stats found for #{node['delivery']['config']['truck']['application']} - returning 99999")
            return 99999
          end
        end
      end

      def save_pmd_violations(node)

        chef_server.with_server_config do
          begin
            databag_item = Chef::DataBagItem.load('delivery', node['delivery']['config']['truck']['application'])
            databag_item.raw_data[PMD_VIOLATIONS] = count_pmd_violations(node)
            databag_item.save()
          rescue Net::HTTPServerException
            Chef::Log.warn("No Databag with Unit Test coverage found for #{node['delivery']['config']['truck']['application']} - creating")
            databag_item = Chef::DataBagItem.new
            databag_item.data_bag('delivery')
            databag_item.raw_data['id'] = node['delivery']['config']['truck']['application']
            databag_item.raw_data[PMD_VIOLATIONS] = count_pmd_violations(node)
            databag_item.create()
          end
        end
      end

      def check_bugs(node)
        current_bugs = count_current_bugs(node)
        previous_bugs = previous_bug_count(node)
        Chef::Log.warn("Findbugs - Previous: #{previous_bugs} Current: #{current_bugs}")
        if (current_bugs > previous_bugs)
          raise RuntimeError, "Number of bugs found with Findbugs has increased from #{previous_bugs} to #{current_bugs}"
        end
      end

      def count_current_bugs(node)
        total = 0;
        Dir.entries(node['delivery']['workspace']['repo']).select {
            |entry| File.directory? File.join(node['delivery']['workspace']['repo'], entry) and !(entry == '..')
        }.collect { |directory|
          current_path_bug_count(directory, node)
        }.each { |result|
          total += result
        }
        return total
      end

      def current_path_bug_count(directory, node)
        path = "#{node['delivery']['workspace']['repo']}/#{directory}/target/findbugsXml.xml"
        pn = Pathname.new(path)
        if (pn.exist?)
          doc = ::File.open(path) { |f| Nokogiri::XML(f) }
          return doc.xpath('/BugCollection/FindBugsSummary/@total_bugs').first.value.to_i
        end
        return 0
      end

      def previous_bug_count(node)
        chef_server.with_server_config do
          begin
            databag_item = Chef::DataBagItem.load('delivery', node['delivery']['config']['truck']['application'])
            return databag_item.raw_data[BUGS] ? databag_item.raw_data[BUGS] : 99999
          rescue Net::HTTPServerException
            Chef::Log.warn("No Databag with complexity stats found for #{node['delivery']['config']['truck']['application']} - returning 99999")
            return 99999
          end
        end
      end

      def save_bug_count(node)
        chef_server.with_server_config do
          begin
            databag_item = Chef::DataBagItem.load('delivery', node['delivery']['config']['truck']['application'])
            databag_item.raw_data[BUGS] = count_current_bugs(node)
            databag_item.save()
          rescue Net::HTTPServerException
            Chef::Log.warn("No Databag with Unit Test coverage found for #{node['delivery']['config']['truck']['application']} - creating")
            databag_item = Chef::DataBagItem.new
            databag_item.data_bag('delivery')
            databag_item.raw_data['id'] = node['delivery']['config']['truck']['application']
            databag_item.raw_data[BUGS] = count_current_bugs(node)
            databag_item.create()
          end
        end
      end

      def check_checkstyle_violations(node)
        previous = previous_checkstyle_violations(node)
        current = count_checkstyle_violations(node)
        if(current > previous)
          raise RuntimeError, "Number of checkstyle errors has increased from #{previous} to #{current}. Failing build"
        end
        Chef::Log.warn("Previous Checkstyle Violations: #{previous}. Current Checkstyle violations #{current}")
      end

      def count_checkstyle_violations(node)
        file = "#{node['delivery']['workspace']['repo']}/target/checkstyle-result.xml"
        doc = ::File.open(file) { |f| Nokogiri::XML(f) }
        return doc.xpath('count(//error)').to_i
      end

      def previous_checkstyle_violations(node)
        chef_server.with_server_config do
          begin
            databag_item = Chef::DataBagItem.load('delivery', node['delivery']['config']['truck']['application'])
            return databag_item.raw_data[CHECKSTYLE] ? databag_item.raw_data[CHECKSTYLE] : 999999
          rescue Net::HTTPServerException
            Chef::Log.warn("No Databag with checkstyle violation stats found for #{node['delivery']['config']['truck']['application']} - returning maximum values")
            return 999999
          end
        end
      end

      def save_checkstyle_count(node)
        chef_server.with_server_config do
          begin
            databag_item = Chef::DataBagItem.load('delivery', node['delivery']['config']['truck']['application'])
            databag_item.raw_data[CHECKSTYLE] = count_checkstyle_violations(node)
            databag_item.save()
          rescue Net::HTTPServerException
            Chef::Log.warn("No Databag with Unit Test coverage found for #{node['delivery']['config']['truck']['application']} - creating")
            databag_item = Chef::DataBagItem.new
            databag_item.data_bag('delivery')
            databag_item.raw_data['id'] = node['delivery']['config']['truck']['application']
            databag_item.raw_data[CHECKSTYLE] = count_checkstyle_violations(node)
            databag_item.create()
          end
        end
      end
      

      private

      def chef_server
        DeliverySugar::ChefServer.new
      end
    end
  end

  module DSL
    def check_pmd?(node)
      CoffeeTruck::Helpers::Lint.check_pmd?(node)
    end

    def count_pmd_violations(node)
      CoffeeTruck::Helpers::Lint.count_pmd_violations(node)
    end

       def save_pmd_violations(node)
      CoffeeTruck::Helpers::Lint.save_pmd_violations(node)
    end

    def check_bugs(node)
      CoffeeTruck::Helpers::Lint.check_bugs(node)
    end

    def save_bug_count(node)
      CoffeeTruck::Helpers::Lint.save_bug_count(node)
    end

    def check_checkstyle_violations(node)
      CoffeeTruck::Helpers::Lint.check_checkstyle_violations(node)
    end

    def save_checkstyle_violations(node)
      CoffeeTruck::Helpers::Lint.save_checkstyle_count(node)
    end

    def count_current_bugs(node)
      CoffeeTruck::Helpers::Lint.count_current_bugs(node)
    end

  end
end