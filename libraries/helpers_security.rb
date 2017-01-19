require 'rubyntlm'


module CoffeeTruck
  module Helpers
    module Lint
      include Chef::Mixin::ShellOut
      extend

      def getSecurityStats()
        request = "https://psdc-pa001gth1v.za.sbicdirectory.com/Cxwebinterface/odata/v1/Projects?$expand=LastScan&$orderby=LastScan/RiskScore%20desc&$top=2"
        message_from_server = Net::HTTP.get(request)
        Chef::Log.warn("Message from server #{message_from_server}")
        t2 = Net::NTLM::Message.parse(message_from_server)
        t3 = t2.response({:user => 'c1592023', :password => 'trendweb'})
        Chef::Log.warn("NTLM Message #{t3}")

      end

    end
  end

  module DSL

    def getSecurityStats()
      CoffeeTruck::Helpers::Lint.getSecurityStats()
    end

  end
end
