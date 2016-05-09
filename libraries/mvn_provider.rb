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
        command = "mvn clean verify -Psonar --fail-at-end #{args}"
        converge_by "Unit tests: #{command}" do
          exec command
        end
      end

      action :sonar do
        command = "mvn sonar:sonar #{args}"
        converge_by "Uploading: #{command}" do
          exec command
        end
      end

      private

      def args
        definitions = @new_resource.definitions.map do |k, v|
          "-D#{k}=#{v}"
        end.join(" ")
        settings = @new_resource.settings ? "-s #{@new_resource.settings} " : ''
        "#{settings}#{definitions}"
      end

      
      def exec(command)
        options = Hash.new
        options[:cwd] = @new_resource.cwd if @new_resource.cwd
        options[:environment] = @new_resource.environment if @new_resource.environment
        shell_out!(command, options).stdout.chomp
      end
    end
  end
end
