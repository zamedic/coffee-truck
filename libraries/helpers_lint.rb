require 'chef/mixin/shell_out'
require 'nokogiri'


module CoffeeTruck
  module Helpers
    module Lint
      include Chef::Mixin::ShellOut
      extend self

      def count_pmd_violations(node)
        file = "#{node['delivery']['workspace']['repo']}/target/pmd.xml"
        doc = ::File.open(file) { |f| Nokogiri::XML(f) }
        doc.xpath("count(//violation)").to_i
      end

      def check_pmd?(node)
        Chef::Log.error(count_violations(node))
      end

    end
  end

  module DSL
    def check_pmd?(node)
      CoffeeTruck::Helpers::Lint.check_pmd?(node)
    end
  end
end