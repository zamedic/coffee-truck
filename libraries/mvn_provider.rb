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

      action :unit do
        command = "mvn clean verify -Punit-tests #{args} --fail-at-end --quiet"
        converge_by "Unit tests: #{command}" do
          exec command
        end
      end

      action :acceptance do
        command = "mvn verify -Pacceptance-tests #{args} --fail-at-end --quiet"
        converge_by "Unit tests: #{command}" do
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
          raise RuntimeError, 'Stop the bus!'
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
        options[:environment] =  {
          'PATH' => "/usr/local/maven-3.3.9/bin:#{ENV['PATH']}"
        }.merge @new_resource.environment
        shell_out!(command, options).stdout.chomp
      end
    end
  end
end
