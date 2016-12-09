require 'nokogiri'

module CoffeeTruck
  module Helpers
    module Unit
      extend self

      def currentCoverage(node)
        missed = 0;
        covered = 0;
        Chef::Log.error("Checking Directory for jacoco reports  #{node['delivery']['workspace']['repo']}")
        Dir.entries(node['delivery']['workspace']['repo']).select{
            |entry| File.directory? File.join(node['delivery']['workspace']['repo'],entry) and !(entry =='.' || entry == '..')
        }.collect{|directory|
          Chef::Log.error("Checking diorectory #{directory}")
          getCoverage(directory,node)
        }.each{|result|
          Chef::Log.error(result)
          missed = missed + result["missed"]
          covered = covered + result["covered"]
        }

        Chef::Log.error("total missed: #{missed} total covered: #{covered}")

      end

      def getCoverage(path,node)
        path = "#{node['delivery']['workspace']['repo']}/#{path}/target/site/jacoco/jacoco.xml"
        pn = Pathname.new(path)
        if(pn.exist?)
          Chef::Log.error("#{path} exists")
          doc = ::File.open(path) { |f| Nokogiri::XML(f) }
          missed = doc.xpath('/report/counter[@type="INSTRUCTION"]/@missed')["value"]
          covered = doc.xpath('/report/counter[@type="INSTRUCTION"]/@covered')["value"]
          {"missed"=> missed, "covered"=> covered}
        else
          Chef::Log.error("#{path} does not exist")
          {"missed"=> 0, "covered"=> 0}
        end
      end

      def sonarmetrics(node)
        uri = URI("#{node['delivery']['config']['sonar']['host']}/api/resources?resource=#{node['delivery']['config']['sonar']['resource']}&metrics=coverage,tests,test_errors,test_failures")
        raw = JSON.parse(Net::HTTP.get(uri))
        metrics = raw[0]['msr'].map do |msr|
          [msr['key'], msr['val']]
        end.to_h
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
    def currentCoverage(node)
      CoffeeTruck::Helpers::Unit.currentCoverage(node)
    end
  end
end
