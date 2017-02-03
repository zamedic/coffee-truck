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
        Chef::Log.warn("Projects previous PMD violations #{previous}, new PMD violations  #{current}.")


      end

      def previous_pmd_violations(node)
        attrs = get_project_application(node['delivery']['config']['truck']['application'])
        if(attrs)
          if(attrs['pmd_violations'])
            return attrs['pmd_violations']
          end
        end
        return 999999
      end

      def previous_complexity(node)
        attrs = get_project_application(node['delivery']['config']['truck']['application'])
        if(attrs)
          if(attrs['complexity'])
            return attrs['complexity']
          end
        end
        return {
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
        return {
            average: average,
            max: {
                complexity:  max,
            }
        }
      end

      def check_complexity?(node)
        previous = previous_complexity(node)
        current = current_complexity(node)

        if(current[:average] > previous[:average])
          raise RuntimeError, "Average Cyclic Complexity increased from #{previous[:average]} to #{current[:average]}. Failing Build"
        end

        if(current[:max][:complexity] > previous[:max])
          raise RuntimeError, "Maximum Cyclic Complexity increased from #{previous[:max]} to #{current[:max][:complexity]}. Failing Build"
        end
        Chef::Log.warn("Projects previous average cyclic complexity #{previous[:average]}, new average cyclic complexity #{current[:average]}.")
        Chef::Log.warn("Projects previous maximum cyclic complexity #{previous[:max]}, new maximum cyclic complexity #{current[:max][:complexity]}.")

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