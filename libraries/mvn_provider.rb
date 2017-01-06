require 'nokogiri'
require 'chef/mixin/shell_out'


class Chef
  class Provider
    class Mvn < Chef::Provider::LWRPBase
      include Chef::Mixin::ShellOut
      use_inline_resources
      provides :mvn

      def whyrun_supported?
        true
      end

      action :unit do
        command = "mvn clean verify -Punit-tests #{args} --fail-at-end | tee maven-unit.log"
        report = "mvn surefire-report:report-only -Daggregate=true #{args}"
        converge_by "Unit tests: #{command}" do
          exec command
          exec report
        end
      end

      action :jacoco_report do
        command = "mvn org.jacoco:jacoco-maven-plugin:report #{args}"
        converge_by "JACOCO Report: #{command}" do
          exec command
          check_failed?(node) unless node['delivery']['config']['truck']['skip_coverage_enforcement']
          if node['delivery']['change']['stage'] == "build"
            http_request 'test-results' do
              action :post
              url 'http://spambot.standardbank.co.za/events/test-results'
              ignore_failure true
              headers('Content-Type' => 'application/json')
              message lazy {
                {
                    application: node['delivery']['config']['truck']['application'],
                    results: sonarmetrics(node)
                }.to_json
              }
            end
          end


        end
      end

      action :functional do
        command = "mvn failsafe:integration-test -Pintegration-tests #{args}  #{node['delivery']['workspace']['repo']}/pom.xml --fail-at-end | tee #{node['delivery']['workspace']['repo']}/mvn-integration-test.log"
        command_verify = "mvn failsafe:verify -Pintegration-tests #{args}  #{node['delivery']['workspace']['repo']}/pom.xml --fail-at-end | tee #{node['delivery']['workspace']['repo']}/mvn-integration-verify.log"
        converge_by "Functional tests: #{command}" do
          system({"DISPLAY" => ":10"},"#{command}")
          system({"DISPLAY" => ":10"},"#{command_verify}")
          upload_functional_results(node)
        end
      end

      action :sonar do
        command = "mvn sonar:sonar #{args} --quiet"
        converge_by "Sonar: #{command}" do
          exec command
        end
      end

      action :upload do
        command = "mvn deploy -Pno-tests #{args} --quiet"
        converge_by "Uploading: #{command}" do
          exec command
        end
      end


      action :release_prepare do
        command_pull = "git pull"
        command_email = "git config user.email 'delivery@standardbank.co.za'"
        command_user = "git config user.name 'Delivery Server'"
        command = "mvn -B release:prepare -Darguments='-Dmaven.test.skip=true' -DupdateWorkingCopyVersions=false -DsuppressCommitBeforeTagOrBranch=true #{args}"
        report = "mvn surefire-report:report-only -Daggregate=true #{args}"
        converge_by "Preparing Release: #{command}" do
          exec command_email
          exec command_user
          exec command_pull
          exec command
          exec report
        end
      end

      action :release_perform do

        command = "mvn -B release:perform  -DupdateWorkingCopyVersions=false -DsuppressCommitBeforeTagOrBranch=true #{args} | tee mvn-release-perform.log"
        converge_by "Performing Release: #{command} to version #{version_number}" do
          exec command
          define_project_application(node['delivery']['change']['project'], version_number, Hash.new)
          sync_envs(node)
        end
      end

      action :pmd do
        if(node['delivery']['config']['truck']['single_level_project'])
          command = "mvn pmd:pmd -Daggregate=false -Dformat=xml #{args}"
        else
          command = "mvn pmd:pmd -Daggregate=true -Dformat=xml #{args}"
        end

        converge_by "running PMD reports against code: #{command}" do
          exec command
          check_pmd?(node) unless node['delivery']['config']['truck']['skip_pmb_enforcement']
          if node['delivery']['change']['stage'] == "build"
            http_request 'lint-results' do
              action :post
              url 'http://spambot.standardbank.co.za/events/lint-results'
              ignore_failure true
              headers('Content-Type' => 'application/json')
              message lazy {
                {
                    application: node['delivery']['config']['truck']['application'],
                    results: {
                        issues: count_pmd_violations(node)
                    }
                }.to_json
              }
            end
          end

        end
      end

      action :checkstyle do
        if(node['delivery']['config']['truck']['single_level_project'])
          command = "mvn -Dcheckstyle.config.location=/tmp/checkstyle.xml checkstyle:checkstyle #{args}"
        else
          command = "mvn -Dcheckstyle.config.location=/tmp/checkstyle.xml checkstyle:checkstyle-aggregate #{args}"
        end

        converge_by "running checkstyle for complexity #{command}" do
          exec command
          check_complexity?(node) unless node['delivery']['config']['truck']['skip_complexity_enforcement']
          if node['delivery']['change']['stage'] == "build"
            http_request 'complexity-results' do
              action :post
              url 'http://spambot.standardbank.co.za/events/quality-results'
              ignore_failure true
              headers('Content-Type' => 'application/json')
              message lazy {
                {
                    application: node['delivery']['config']['truck']['application'],
                    results: current_complexity(node)
                }.to_json
              }
            end
          end

        end
      end


      action :compile do
        command = "mvn compile package install -Dmaven.test.skip=true #{args}"
        converge_by "running compile #{command}" do
          exec command
        end
      end

      private

      def args
        definitions = @new_resource.definitions.map do |k, v|
          v ? "-D#{k}=#{v}" : "-D#{k}"
        end.join(" ")
        settings = "-s #{@new_resource.settings || node['maven']['settings']}"
        "#{settings} #{definitions}"
      end


      def exec(command)
        options = Hash.new
        options[:cwd] = @new_resource.cwd || node['delivery']['workspace']['repo']
        options[:timeout] = 1200
        options[:environment] = {
            'PATH' => "/usr/local/maven-3.3.9/bin:#{ENV['PATH']}"
        }.merge @new_resource.environment
        shell_out!(command, options).stdout.chomp
      end

      def version_number
        cwd = @new_resource.cwd || node['delivery']['workspace']['repo']
        path = "#{cwd}/pom.xml"
        doc = ::File.open(path) { |f| Nokogiri::XML(f) }
        doc.xpath('/xmlns:project/xmlns:version/text()').first.content.sub('-SNAPSHOT', '')
      end
    end
  end
end
