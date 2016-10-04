module CoffeeTruck
  module Helpers
    module Unit
      extend self

      def sonarmetrics(node)
        cwd = node['delivery']['workspace']['repo']
        command = "curl -X GET '#{node['delivery']['config']['sonar']['host']}/api/resources?resource=#{node['delivery']['config']['sonar']['resource']}&metrics=coverage,tests,test_errors,test_failures'"
          raw = JSON.parse `cd #{cwd} && #{command}`
          Chef::Log.error "RAW"
          Chef::Log.error raw
          metrics = raw[0]['msr'].map do |msr|
            [msr['key'], msr['val']]
          end.to_h
          Chef::Log.error "METRICS"
          Chef::Log.error metrics
        {
          coverage: metrics['coverage'],
          unit: {
            total: metrics['tests'],
            errors: metrics['test_errors'],
            failures: metrics['test_failures']
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
