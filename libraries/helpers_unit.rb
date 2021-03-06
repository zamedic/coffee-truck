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
        missed = 0
        covered = 0
        complexity_sum = 0
        complexity_count = 0
        complexity_max = 0
        Dir.entries(node['delivery']['workspace']['repo']).select {
            |entry| File.directory? File.join(node['delivery']['workspace']['repo'], entry) and !(entry == '..')
        }.collect {|directory|
          current_path_unit_coverage(directory, node)
        }.each {|result|
          missed = missed + result[:missed]
          covered = covered + result[:covered]
          complexity_sum = complexity_sum + result[:complexity][:sum]
          complexity_count = complexity_count + result[:complexity][:count]
          if result[:complexity][:max] > complexity_max
            complexity_max = result[:complexity][:max]
          end
        }
        if (covered.to_f + missed.to_f) == 0.0
          raise RuntimeError, 'Project coverage is 0%. Please check your pom.xml to ensure you have enabled jacoco else add some tests'
        end

        coverage = covered.to_f / (covered.to_f + missed.to_f) * 100.0
        complexity = complexity_sum.to_f / complexity_count.to_f

        {coverage: ((coverage*1000).round / 1000.0).to_f, max_complexity: complexity_max, average_complexity: (((complexity * 100).round)/100.0).to_f}
      end

      def current_path_unit_coverage(path, node)
        path = "#{node['delivery']['workspace']['repo']}/#{path}/target/site/jacoco/jacoco.xml"
        pn = Pathname.new(path)
        if (pn.exist?)
          doc = ::File.open(path) {|f| Nokogiri::XML(f)}
          this_missed = doc.xpath('/report/counter[@type="LINE"]/@missed').first.value.to_i
          this_covered = doc.xpath('/report/counter[@type="LINE"]/@covered').first.value.to_i

          {missed: this_missed, covered: this_covered, complexity: calculate_complexity(doc)}
        else
          {missed: 0, covered: 0, complexity: {max: 0, sum: 0, count: 0}}
        end
      end

      def calculate_complexity(doc)
        max = 0
        sum = 0
        complexities = doc.xpath('/report/package/class/method/counter[@type="COMPLEXITY"]')
        complexities.each do |complexity|
          item_value = complexity.xpath('@missed').first.value.to_i + complexity.xpath('@covered').first.value.to_i
          if item_value > max
            max = item_value
          end
          sum = sum + item_value
        end
        {max: max, sum: sum, count: complexities.length}

      end


      def check_failed?(node)
        coverage = current_unit_coverage(node)
        if (coverage[:coverage] == 0.0)
          raise RuntimeError, 'Project coverage is 0%. Please check your pom.xml to ensure you have enabled jacoco else add some tests'
        end
        previous = previous_unit_coverage(node)
        if (previous > coverage[:coverage])
          raise RuntimeError, "Project coverage has dropped from #{previous} to #{coverage[:coverage]}. Failing Build"
        end
        Chef::Log.warn("Project previous coverage #{previous}%, new coverage #{coverage[:coverage]}%.")
        Chef::Log.warn("Project complexity #{coverage[:average_complexity]}, max complexity #{coverage[:max_complexity]}")
        return true
      end

      def get_unit_test_count(node)
        file = "#{node['delivery']['workspace']['repo']}/target/site/surefire-report.html"
        doc = ::File.open(file) {|f| Nokogiri::XML(f)}
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
        }.collect {|directory|
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
          }.collect {|surefire|
            check_surefire_file("#{path}/#{surefire}")
          }.select {|item| item == true}.length
          if (errors > 0)
            raise RuntimeError, 'Failing build due to previous warning related to either unit test speed or errors.'
          end
        end
      end

      def check_surefire_file(surefire)
        doc = ::File.open(surefire) {|f| Nokogiri::XML(f)}
        failed = false
        doc.xpath('/testsuite/testcase').each {|testcase|
          runtime = testcase.xpath('@time').first.text.to_f
          name = testcase.xpath('@name').first.text
          class_name = testcase.xpath('@classname').first.text

          if (runtime > 3)
            Chef::Log.warn("Runtime for test #{name} in class #{class_name} has a runtime of #{runtime}, this exceeded the 3 second threshold. This is probably not a valid unit test")
          end
          testcase.xpath('failure').each {|error|
            Chef::Log.error("the following error was encountered with unit test #{name} in class #{class_name}. #{error.xpath('@message')}")
            failed = true
          }
          testcase.xpath('error').each {|error|
            Chef::Log.error("the following error was encountered with unit test #{name} in class #{class_name}. #{error.xpath('@message')}")
            failed = true
          }
        }
        return failed
      end

      def sonarmetrics(node)
        current_coverage =current_unit_coverage(node)
        {
            unit: get_unit_test_count(node),
            coverage: current_coverage[:coverage],
            complexity: {
                average_complexity: current_coverage[:average_complexity],
                max_complexity: current_coverage[:max_complexity]
            }
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
        chef_server.with_server_config do
          Chef::Log.warn("loading data bag for #{node['delivery']['config']['truck']['application']}")
          databag = Chef::DataBagItem.load('delivery', node['delivery']['config']['truck']['application']).raw_data
          Chef::Log.warn("databag value: #{databag}")
          return databag
        end
      end

      def unit_coverage(node)
        begin
          load_data_bag(node)[unit_coverage_key]['coverage'].to_f
        rescue
          0.to_f
        end

      end

      def unit_failed_tests(node)
        begin
          load_data_bag(node)[unit_coverage_key]['unit']['failures']
        rescue
          0
        end

      end

      def unit_error_tests(node)
        begin
          load_data_bag(node)[unit_coverage_key]['unit']['errors']
        rescue
          0
        end

      end

      def unit_total_tests(node)
        begin
          load_data_bag(node)[unit_coverage_key]['unit']['total']
        rescue
          0
        end
      end

      def max_complexity(node)
        begin
          load_data_bag(node)[unit_coverage_key]['complexity']['max_complexity']
        rescue
          0
        end
      end

      def average_complexity(node)
        begin
          value = load_data_bag(node)[unit_coverage_key]['complexity']['average_complexity']
        rescue
          0.to_f
        end

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

    def max_complexity(node)
      CoffeeTruck::Helpers::Unit.max_complexity(node)
    end

    def average_complexity(node)
      CoffeeTruck::Helpers::Unit.average_complexity(node)
    end


  end
end
