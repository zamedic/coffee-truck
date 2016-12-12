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
          missed = missed + result[:missed]
          covered = covered + result[:covered]
        }

        Chef::Log.error("total missed: #{missed} total covered: #{covered}")
        coverage = covered.to_f / (covered.to_f + missed.to_f) * 100.0
        coverage = (coverage*10).round / 10.0


        Chef::Log.error("coverage percentage: #{coverage}")
        Chef::Log.error("previous coverage percentage: #{sonarmetrics(node)[:coverage]}")
      end

      def getCoverage(path,node)
        path = "#{node['delivery']['workspace']['repo']}/#{path}/target/site/jacoco/jacoco.xml"
        pn = Pathname.new(path)
        if(pn.exist?)
          Chef::Log.error("#{path} exists")
          doc = ::File.open(path) { |f| Nokogiri::XML(f) }
          this_missed = doc.xpath('/report/counter[@type="LINE"]/@missed').first.value.to_i
          this_covered = doc.xpath('/report/counter[@type="LINE"]/@covered').first.value.to_i
          {missed: this_missed, covered: this_covered}
        else
          Chef::Log.error("#{path} does not exist")
          {missed: 0, covered: 0}
        end
      end

      def getPreviousCoverage(node)
        uri = URI("http://demoncat.standardbank.co.za/testing/#{node['delivery']['config']['truck']['application']}")
        raw = JSON.parse(Net::HTTP.get(uri))
        return raw["coverage"].to_f
      end

      def check_failed?(node)
        coverage = currentCoverage(node)
        if (coverage == 0)
          raise RuntimeError,"Project coverage is 0%. Please check your pom.xml to ensure you have enabled jacoco else add some tests"
        end
        previous = getPreviousCoverage(node)
        if (previous > coverage)
          raise RuntimeError,"Project coverage is dropped from #{previous} to #{coverage}. Failing Build"
        end
        return true
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
    def check_failed(node)
      CoffeeTruck::Helpers::Unit.check_failed?(node)
    end
  end
end
