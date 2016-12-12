require 'nokogiri'

module CoffeeTruck
  module Helpers
    module Unit
      extend self

      def currentCoverage(node)
        missed = 0;
        covered = 0;
        Dir.entries(node['delivery']['workspace']['repo']).select {
            |entry| File.directory? File.join(node['delivery']['workspace']['repo'], entry) and !(entry =='.' || entry == '..')
        }.collect { |directory|
          getCoverage(directory, node)
        }.each { |result|
          Chef::Log.error(result)
          missed = missed + result[:missed]
          covered = covered + result[:covered]
        }

        coverage = covered.to_f / (covered.to_f + missed.to_f) * 100.0
        return ((coverage*10).round / 10.0).to_f
      end

      def getCoverage(path, node)
        path = "#{node['delivery']['workspace']['repo']}/#{path}/target/site/jacoco/jacoco.xml"
        pn = Pathname.new(path)
        if (pn.exist?)
          doc = ::File.open(path) { |f| Nokogiri::XML(f) }
          this_missed = doc.xpath('/report/counter[@type="LINE"]/@missed').first.value.to_i
          this_covered = doc.xpath('/report/counter[@type="LINE"]/@covered').first.value.to_i
          {missed: this_missed, covered: this_covered}
        else
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
        if (coverage == 0.0)
          raise RuntimeError, "Project coverage is 0%. Please check your pom.xml to ensure you have enabled jacoco else add some tests"
        end
        previous = getPreviousCoverage(node)
        if (previous > coverage)
          raise RuntimeError, "Project coverage has dropped from #{previous} to #{coverage}. Failing Build"
        end
        return true
      end

      def get_unit_test_count(node)

        file = "#{node['delivery']['workspace']['repo']}/target/site/surefire-report.html"
        doc = ::File.open(file) { |f| Nokogiri::XML(f) }
        total_tests = doc.xpath("/x:html/x:body/x:div[@id='bodyColumn']/x:div/x:div[2]/x:table/x:tr[2]/x:td[1]/text()",'x' => 'http://www.w3.org/1999/xhtml').first.text.to_i
        Chef::Log.error("total tests: #{total_tests}")
        skipped_tests=doc.xpath("/x:html/x:body/x:div[@id='bodyColumn']/x:div/x:div[2]/x:table/x:tr[2]/x:td[4]/text()",'x' => 'http://www.w3.org/1999/xhtml').first.text.to_i
        Chef::Log.error("skipped tests: #{skipped_tests}")
        error_test=0
        failed_tests=0
        return {
            total: total_tests-skipped_tests,
            errors: error_test,
            failures: failed_tests
        }
      end

      def sonarmetrics(node)
        {
            coverage: currentCoverage(node),
            unit: get_unit_test_count(node)
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

    def check_failed?(node)
      CoffeeTruck::Helpers::Unit.check_failed?(node)
    end
  end
end
