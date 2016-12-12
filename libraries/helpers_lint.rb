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

        if (current > previous)
          raise RuntimeError, "PMD violations increased from #{previous} to #{current}. Failing Build"
        end
      end

      def current_pmd_violations(node)
        uri = URI("http://demoncat.standardbank.co.za/quality/#{node['delivery']['config']['truck']['application']}")
        raw = JSON.parse(Net::HTTP.get(uri))
        return raw["lint"]["issues"].to_f
      end

      def current_complexity(node)
        count = 0;
        sum = 0;
        max = 0;
        file = "#{node['delivery']['workspace']['repo']}/target/checkstyle-result.xml"
        doc = ::File.open(file) { |f| Nokogiri::XML(f) }
        doc.xpath("//error[@source='com.puppycrawl.tools.checkstyle.checks.metrics.CyclomaticComplexityCheck']/@message").each { |row|
          value = row[25..-1]
          value = value[0..value.index(' ')]
          Chef::Log.error("value #{value}")
          if (value > max)
            max = value
          end

          count = count + 1
          sum = sum + value
        }
        if(count == 0)
          raise RuntimeError, "No cyclic complexity records found. Failing Build. Blame Marc"
        end
        average = ((sum.to_f/count.to_f)*100.round / 100.0).to_f
        {
            max: max,
            average: average
        }
        Chef::Log.error("average #{average}, max #{max}")
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

    def current_complexity(node)
      CoffeeTruck::Helpers::Lint.current_complexity(node)
    end
  end
end