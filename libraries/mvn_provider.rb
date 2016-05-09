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
        converge_by "Running Unit Tests" do
          exec 'mvn clean verify -Psonar --fail-at-end'
        end
      end

      private

      def args
        definitions = @new_resource.definitions.map do |k, v|
          "-D#{k}=#{v}"
        end.join(" ")
        settings = "-s #{@new_resource.settings}"
        "#{settings} #{definitions}"
      end

      def exec(command)
        options = Hash.new
        options[:cwd] = @new_resource.cwd if @new_resource.cwd
        options[:environment] = @new_resource.environment if @new_resource.environment
        shell_out!("#{command} #{args}", options).stdout.chomp
      end
    end
  end
end
