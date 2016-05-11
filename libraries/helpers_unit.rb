module CoffeeTruck
  module Helpers
    module Unit
      extend self

      def sonarmetrics(node)
        cwd = node['delivery']['workspace']['repo']
        command = "curl -X GET '#{node['delivery']['config']['sonar']['host']}/api/resources?resource=#{node['delivery']['config']['sonar']['resource']}&metrics=ncloc,coverage,tests,test_errors,test_failures'"
        begin
          raw = JSON.parse `cd #{cwd} && #{command}`
          metrics = raw[0]['msr'].map do |msr|
            [msr['key'], msr['val']]
          end.to_h
        rescue
          metrics = {}
        end
        {
          lines: metrics['ncloc'],
          coverage: metrics['coverage'],
          unit: {
            total: metrics['tests'],
            errors: metrics['test_errors'],
            failures: metrics['test_failures']
          },
          integration: {
          },
          acceptance: {
          }
        }
      end
    end
  end

  module DSL

    def sonarmetrics(node)
      CoffeeTruck::Helpers::Unit.sonarmetrics(node)
    end
  end
end
