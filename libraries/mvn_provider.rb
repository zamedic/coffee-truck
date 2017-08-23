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
        if (node['delivery']['config']['truck']['single_level_project'])
          report = "mvn surefire-report:report-only #{args}"
        else
          report = "mvn surefire-report:report-only -Daggregate=true #{args}"
        end

        converge_by "Unit tests: #{command}" do
          exec command
          exec report
          check_surefire_errors(node)
        end
      end

      action :jacoco_report do
        command = "mvn org.jacoco:jacoco-maven-plugin:report #{args}  | tee maven-jacoco.log"
        converge_by "JACOCO Report: #{command}" do
          exec command
          check_failed?(node) unless node['delivery']['config']['truck']['skip_coverage_enforcement']
          if node['delivery']['change']['stage'] == "build"
            save_test_results(node)
          end


        end
      end

      action :functional do
        command_verify = "mvn failsafe:verify -Pintegration-tests #{args} -f #{node['delivery']['workspace']['repo']}/pom.xml -Dwebdriver.gecko.driver=/usr/bin/geckodriver -q| tee #{node['delivery']['workspace']['repo']}/mvn-integration-test.log"
        converge_by "Functional tests: #{command_verify}" do
          exec command_verify
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
        command_email = "git config user.email '#{node['coffee-truck']['release']['email']}'"
        command_user = "git config user.name '#{node['coffee-truck']['release']['user']}'"
        command = "mvn -B release:prepare -Darguments='-Dmaven.test.skip=true' -DupdateWorkingCopyVersions=false -DsuppressCommitBeforeTagOrBranch=true #{args} | tee mvn-release-prepare.log"
        report = "tail -40  mvn-release-prepare.log | grep 'BUILD SUCCESS'"
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
        report = "tail -40 mvn-release-perform.log | grep 'BUILD SUCCESS'"
        converge_by "Performing Release: #{command} to version #{version_number}" do
          exec command
          exec report
          define_project_application(node['delivery']['change']['project'], version_number, Hash.new)
        end
      end

      action :pmd do
        if (node['delivery']['config']['truck']['single_level_project'])
          command = "mvn pmd:pmd -Daggregate=false -Dformat=xml #{args}"
        else
          command = "mvn pmd:pmd -Daggregate=true -Dformat=xml #{args}"
        end

        converge_by "running PMD reports against code: #{command}" do
          exec command
          check_pmd?(node) unless node['delivery']['config']['truck']['skip_pmb_enforcement']
          if node['delivery']['change']['stage'] == "build"
            save_pmd_violations(node)
          end
        end
      end

      action :checkstyle do
        if (node['delivery']['config']['truck']['single_level_project'])
          command = "mvn checkstyle:checkstyle #{args}"
        else
          command = "mvn checkstyle:checkstyle-aggregate #{args}"
        end

        converge_by "running checkstyle for complexity #{command}" do
          exec command
          check_checkstyle_violations(node) unless node['delivery']['config']['truck']['skip_complexity_enforcement']
          if node['delivery']['change']['stage'] == "build"
            save_checkstyle_violations(node)
          end
        end
      end

      action :findbugs do
        command = "mvn findbugs:findbugs #{args}"
        converge_by "running findbugs #{command}" do
          exec command
          check_bugs(node) unless node['delivery']['config']['truck']['skip_findbugs_enforcement']
          if node['delivery']['change']['stage'] == "build"
            save_bug_count(node)
          end
        end

      end

      action :compile do
        command = "mvn -U compile package install -Dmaven.test.skip=true #{args}"
        converge_by "running compile #{command}" do
          exec command
        end
      end

      action :security do
        command = "mvn findbugs:findbugs -Psecurity #{args}"
        converge_by "running security scan #{command}" do
          exec command
        end
      end

      action :updateDependencies do
        command = 'mvn versions:use-latest-releases'
        if node['delivery']['config']['truck']['update_dependencies']['include']
          command = "#{command} -Dincludes=#{node['delivery']['config']['truck']['update_dependencies']['include']}"
        end
        command_commit_bump = 'mvn versions:commit'
        command_email = "git config user.email '#{node['coffee-truck']['release']['email']}'"
        command_user = "git config user.name '#{node['coffee-truck']['release']['user']}'"
        command_update = 'git add --all'
        command_commit = 'git commit -m "updating pom to latest"'
        command_push = 'git push'

        converge_by "bumping versions: #{command}" do
          begin
            exec command
            exec command_commit_bump
            exec command_email
            exec command_user
            exec command_update
            exec command_commit
            exec command_push
          rescue
            Chef::Log.warn("Bump failed - chances are that nothing needed to be bumped")
          end
        end
      end

      action :cpd do
        command = "mvn pmd:cpd -Daggregate=true #{args}"
        converge_by "running cpd detection #{command}" do
          exec command
          checkCpd(node)
        end


      end

      private

      def args
        if (node['coffee-truck']['maven']['settings'])
          "-s #{node['coffee-truck']['maven']['settings']}"
        end
      end

      def exec(command)

        options = Hash.new
        options[:cwd] = @new_resource.cwd || node['delivery']['workspace']['repo']
        options[:timeout] = 3000
        options[:environment] = {
            'PATH' => "#{node['maven']['m2_home']}-#{node['maven']['version']}/bin:#{ENV['PATH']}", "DISPLAY" => ":10"
        }.merge @new_resource.environment
        Chef::Log.warn("Executing #{command} ")
        out = shell_out!(command, options)
        if out.exitstatus != 0
          raise RuntimeError, "Execution Failed. "
        end
        out.stdout.chomp
      end

      def version_number
        cwd = @new_resource.cwd || node['delivery']['workspace']['repo']
        path = "#{cwd}/pom.xml"
        doc = ::File.open(path) {|f| Nokogiri::XML(f)}
        doc.xpath('/xmlns:project/xmlns:version/text()').first.content.sub('-SNAPSHOT', '')
      end
    end
  end
end
