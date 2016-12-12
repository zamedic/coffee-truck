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
        current = count_pmd_violations(node)
        previous = current_pmd_violations(node)

        if(current > previous)
          raise RuntimeError, "PMD violations increased from #{previous} to #{current}. Failing Build"
        end
      end

      def current_pmd_violations(node)
        uri = URI("http://demoncat.standardbank.co.za/quality/#{node['delivery']['config']['truck']['application']}")
        raw = JSON.parse(Net::HTTP.get(uri))
        return raw["lint"]["issues"].to_f
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
  end
end