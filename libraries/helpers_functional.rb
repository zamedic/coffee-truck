require 'nokogiri'

module CoffeeTruck
  module Helpers
    module Functional
      extend self

      def current_coverage(node)
        total = 0
        Dir.entries(node['delivery']['workspace']['repo']).select {
            |entry| File.directory? File.join(node['delivery']['workspace']['repo'], entry) and !(entry == '..')
        }.collect { |directory|
          getCoverage(directory, node)
        }.each { |result|
          total = total + result
        }
        Chef::Log.warn("Integration Tests: #{total}")
        return total
      end

      def getCoverage(path,node)
        path = "#{node['delivery']['workspace']['repo']}/#{path}/target/failsafe-reports/failsafe-summary.xml"
        pn = Pathname.new(path)
        if (pn.exist?)
          doc = ::File.open(path) { |f| Nokogiri::XML(f) }
          doc.xpath("/failsafe-summary/completed/text()").first.text.to_i
        else
          0
        end
      end

      def functional_metrics(node)
        total = current_coverage(node)
        {
            functional: {
                total: total,
                success: total
            }
        }
      end

      def upload_functional_results(node)

      end
    end
  end

  module DSL
    def functional_metrics(node)
      CoffeeTruck::Helpers::Functional.functional_metrics(node)
    end
  end
end
