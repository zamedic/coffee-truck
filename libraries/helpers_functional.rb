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
        {
            functional: {
                total: current_coverage(node)
            }
        }
      end

      def upload_functional_results(node)
        http_request 'test-results' do
          action :post
          url 'http://spambot.standardbank.co.za/events/test-results'
          ignore_failure true
          headers('Content-Type' => 'application/json')
          message lazy {
            {
                application: node['delivery']['config']['truck']['application'],
                results: functional_metrics(node)
            }.to_json
          }
        end
      end
    end
  end
end
