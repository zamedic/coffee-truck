require 'nokogiri'
require 'net/http'

module CoffeeTruck
  module Helpers
    module Unit
      extend self

      @@unit_coverage = 'unit_coverage'

      def unit_coverage_key
        @@unit_coverage
      end

      def current_unit_coverage(node)
        missed = 0;
        covered = 0;
        Dir.entries(node['delivery']['workspace']['repo']).select {
            |entry| File.directory? File.join(node['delivery']['workspace']['repo'], entry) and !(entry == '..')
        }.collect { |directory|
          current_path_unit_coverage(directory, node)
        }.each { |result|
          missed = missed + result[:missed]
          covered = covered + result[:covered]
        }
        if ((covered.to_f + missed.to_f) == 0.0)
          raise RuntimeError, 'Project coverage is 0%. Please check your pom.xml to ensure you have enabled jacoco else add some tests'
        end

        coverage = covered.to_f / (covered.to_f + missed.to_f) * 100.0
        return ((coverage*1000).round / 1000.0).to_f
      end

      def current_path_unit_coverage(path, node)
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


      def check_failed?(node)
        coverage = current_unit_coverage(node)
        if (coverage == 0.0)
          raise RuntimeError, 'Project coverage is 0%. Please check your pom.xml to ensure you have enabled jacoco else add some tests'
        end
        previous = previous_unit_coverage(node)
        if (previous > coverage)
          raise RuntimeError, "Project coverage has dropped from #{previous} to #{coverage}. Failing Build"
        end
        Chef::Log.warn("Project previous coverage #{previous}%, new coverage #{coverage}%.")
        return true
      end

      def get_unit_test_count(node)
        file = "#{node['delivery']['workspace']['repo']}/target/site/surefire-report.html"
        doc = ::File.open(file) { |f| Nokogiri::XML(f) }
        total_tests = doc.xpath("/x:html/x:body/x:div[@id='bodyColumn']/x:div/x:div[2]/x:table/x:tr[2]/x:td[1]/text()", 'x' => 'http://www.w3.org/1999/xhtml').first.text.to_i
        error_test=doc.xpath("/x:html/x:body/x:div[@id='bodyColumn']/x:div/x:div[2]/x:table/x:tr[2]/x:td[2]/text()", 'x' => 'http://www.w3.org/1999/xhtml').first.text.to_i
        failed_tests=doc.xpath("/x:html/x:body/x:div[@id='bodyColumn']/x:div/x:div[2]/x:table/x:tr[2]/x:td[3]/text()", 'x' => 'http://www.w3.org/1999/xhtml').first.text.to_i
        skipped_tests=doc.xpath("/x:html/x:body/x:div[@id='bodyColumn']/x:div/x:div[2]/x:table/x:tr[2]/x:td[4]/text()", 'x' => 'http://www.w3.org/1999/xhtml').first.text.to_i
        Chef::Log.warn("Tests - Total: #{total_tests} Skipped: #{skipped_tests} Error: #{error_test} Failed: #{failed_tests} ")
        if (error_test > 0)
          raise RuntimeError, "#{error_test} tests failed with an error. Failing Build"
        end
        if (failed_tests > 0)
          raise RuntimeError, "#{failed_tests} tests failed with an test case failure. Failing Build"
        end
        if (total_tests == 0)
          raise RuntimeError, 'No tests detected. Either the tests failed or you have no tests'
        end
        return {
            total: total_tests-skipped_tests,
            errors: error_test,
            failures: failed_tests
        }
      end

      def check_surefire_errors(node)
        Dir.entries(node['delivery']['workspace']['repo']).select {
            |entry| File.directory? File.join(node['delivery']['workspace']['repo'], entry) and !(entry == '..')
        }.collect { |directory|
          check_folder_for_surefire_errors(node, directory)
        }
        get_unit_test_count(node)
      end

      def check_folder_for_surefire_errors(node, directory)
        path = "#{node['delivery']['workspace']['repo']}/#{directory}/target/surefire-reports"
        pn = Pathname.new(path)
        if (pn.exist?)
          errors = Dir.entries(path).select {
              |entry| entry.end_with?('.xml')
          }.collect { |surefire|
            check_surefire_file("#{path}/#{surefire}")
          }.select { |item| item == true }.length
          if (errors > 0)
            raise RuntimeError, 'Failing build due to previous warning related to either unit test speed or errors.'
          end
        end
      end

      def check_surefire_file(surefire)
        doc = ::File.open(surefire) { |f| Nokogiri::XML(f) }
        failed = false
        doc.xpath('/testsuite/testcase').each { |testcase|
          runtime = testcase.xpath('@time').first.text.to_f
          name = testcase.xpath('@name').first.text
          class_name = testcase.xpath('@classname').first.text

          if (runtime > 3)
            Chef::Log.warn("Runtime for test #{name} in class #{class_name} has a runtime of #{runtime}, this exceeded the 3 second threshold. This is probably not a valid unit test")
          end
          testcase.xpath('failure').each { |error|
            Chef::Log.error("the following error was encountered with unit test #{name} in class #{class_name}. #{error.xpath('@message')}")
            failed = true
          }
        }
        return failed
      end

      def sonarmetrics(node)
        {
            unit: get_unit_test_count(node),
            coverage: current_unit_coverage(node),
        }
      end

      def previous_unit_coverage(node)
        chef_server.with_server_config do
          begin
            databag_item = Chef::DataBagItem.load('delivery', node['delivery']['config']['truck']['application'])
            return databag_item.raw_data[unit_coverage_key] && databag_item.raw_data[unit_coverage_key]['coverage'] ? databag_item.raw_data[unit_coverage_key]['coverage'] : 0
          rescue Net::HTTPServerException
            Chef::Log.warn("No Databag with Unit Test coverage found for #{node['delivery']['config']['truck']['application']} - returning 0")
            return 0
          end

        end
      end


      def save_test_results(node)
        chef_server.with_server_config do
          begin
            databag_item = Chef::DataBagItem.load('delivery', node['delivery']['config']['truck']['application'])
            databag_item.raw_data[unit_coverage_key] = sonarmetrics(node)
            databag_item.save()
          rescue Net::HTTPServerException
            Chef::Log.warn("No Databag with Unit Test coverage found for #{node['delivery']['config']['truck']['application']} - creating")
            databag_item = Chef::DataBagItem.new
            databag_item.data_bag('delivery')
            databag_item.raw_data['id'] = node['delivery']['config']['truck']['application']
            databag_item.raw_data[unit_coverage_key] = sonarmetrics(node)
            databag_item.create()
          end
        end
      end

      def load_data_bag(node)
        Chef::DataBagItem.load('delivery', node['delivery']['config']['truck']['application']).raw_data
      end

      def unit_coverage(node)
        load_data_bag(node)['coverage']
      end

      def unit_failed_tests(node)
        load_data_bag(node)['unit']['failures']
      end

      def unit_error_tests(node)
        load_data_bag(node)['unit']['errors']
      end

      def unit_total_tests(node)
        load_data_bag(node)['unit']['total']
      end

      private

      def chef_server
        DeliverySugar::ChefServer.new
      end
    end
  end

  module DSL

    def check_failed?(node)
      CoffeeTruck::Helpers::Unit.check_failed?(node)
    end

    def check_surefire_errors(node)
      CoffeeTruck::Helpers::Unit.check_surefire_errors(node)
    end

    def save_test_results(node)
      CoffeeTruck::Helpers::Unit.save_test_results(node)
    end

    def unit_coverage(node)
      CoffeeTruck::Helpers::Unit.unit_coverage(node)
    end

    def unit_failed_tests(node)
      CoffeeTruck::Helpers::Unit.unit_failed_tests(node)
    end

    def unit_error_tests(node)
      CoffeeTruck::Helpers::Unit.unit_error_tests(node)
    end

    def unit_total_tests(node)
      CoffeeTruck::Helpers::Unit.unit_total_tests(node)
    end
  end
end
