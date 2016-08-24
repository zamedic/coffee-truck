require 'nokogiri'
require 'chef/mixin/shell_out'


class  Chef
  class Provider
    class Mvn < Chef::Provider::LWRPBase
      include Chef::Mixin::ShellOut
      use_inline_resources
      provides :mvn

      def whyrun_supported?
        true
      end

      def final_version
        version_number
      end

      action :unit do
        command = "mvn clean verify -Punit-tests #{args} --fail-at-end --quiet"
        converge_by "Unit tests: #{command}" do
          exec command
        end
      end

      action :functional do
        command = "mvn verify -Pintegration-tests #{args} --fail-at-end --quiet"
        converge_by "Functional tests: #{command}" do
          exec command
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
        converge_by "Preparing Release: #{command}" do
          exec command_email
          exec command_user
          exec command_pull
          exec command
        end
      end

      action :release_perform do

        command = "mvn -X -B release:perform -DupdateWorkingCopyVersions=false -DsuppressCommitBeforeTagOrBranch=true #{args} > /tmp/marc.log"
        converge_by "Preparing Release: #{command}" do
          exec command
          define_project_application(node['delivery']['change']['project'], final_version, Hash.new)
          sync_envs(node)
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
        options[:environment] =  {
          'PATH' => "/usr/local/maven-3.3.9/bin:#{ENV['PATH']}"
        }.merge @new_resource.environment
        shell_out!(command, options).stdout.chomp
      end

      def version_number
        cwd = @new_resource.cwd || node['delivery']['workspace']['repo']
        path = "#{cwd}/pom.xml"
        doc = ::File.open(path) { |f| Nokogiri::XML(f) }
        doc.xpath('/xmlns:project/xmlns:version/text()').first.content.sub('-SNAPSHOT','')
      end
    end
  end
end
