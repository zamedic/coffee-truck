require 'nokogiri'
require 'chef/mixin/shell_out'


class Chef
  class Provider
    class Checkmarx < Chef::Provider::LWRPBase
      include Chef::Mixin::ShellOut
      use_inline_resources
      provides :checkmarx

      def whyrun_supported?
        true
      end

      action :update_demoncat do
        converge_by "Retreiving Security stats from checkmarx" do
          if(node['delivery']['config']['truck']['security_url'])
            getSecurityStats(node)
          end
        end

      end

      private

    end
  end
end
