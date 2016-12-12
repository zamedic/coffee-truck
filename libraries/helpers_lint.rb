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
        previous = previous_pmd_violations(node)

        if (current > previous)
          raise RuntimeError, "PMD violations increased from #{previous} to #{current}. Failing Build"
        end
      end

      def previous_pmd_violations(node)
        uri = URI("http://demoncat.standardbank.co.za/quality/#{node['delivery']['config']['truck']['application']}")
        raw = JSON.parse(Net::HTTP.get(uri))
        issues = raw["lint"]["issues"]
        issues ? issues.to_i : 999999
      end

      def previous_complexity(node)
        uri = URI("http://demoncat.standardbank.co.za/quality/#{node['delivery']['config']['truck']['application']}")
        raw = JSON.parse(Net::HTTP.get(uri))
        average = raw["complexity"]["average"]
        max=raw["complexity"]["max"]["complexity"]
        {
            average: average ? average.to_f : 999.0,
            max: max ? max.to_i : 999
        }
      end



      def current_complexity(node)
        count = 0;
        sum = 0;
        max = 0;
        file = "#{node['delivery']['workspace']['repo']}/target/checkstyle-result.xml"
        doc = ::File.open(file) { |f| Nokogiri::XML(f) }
        doc.xpath("//error[@source='com.puppycrawl.tools.checkstyle.checks.metrics.CyclomaticComplexityCheck']/@message").each { |row|
          value = row.to_s[25..-1]
          value = value[0..value.index(' ')].to_i
          if (value > max)
            max = value
          end

          count = count + 1
          sum = sum + value
        }
        if(count == 0)
          raise RuntimeError, "No cyclic complexity records found. Failing Build. Blame Marc"
        end
        average = (((sum.to_f/count.to_f)*100).round / 100.0).to_f
        {
            average: average,
            max: {
                complexity: max,
            }
        }
        Chef::Log.error("average #{average}, max #{max}")
      end

      def check_complexity?(node)
        previous = previous_complexity(node)
        current = current_complexity(node)

        if(current["average"] > previous["average"])
          raise RuntimeError, "Average Cyclic Complexity increased from #{previous["average"]} to #{current["average"]}. Failing Build"
        end

        if(current["max"]["complexity"] > previous["max"])
          raise RuntimeError, "Maximum Cyclic Complexity increased from #{previous["max"]["complexity"]} to #{current["max"]}. Failing Build"
        end

        return true
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

    def check_complexity?(node)
      CoffeeTruck::Helpers::Lint.check_complexity?(node)
    end
  end
end