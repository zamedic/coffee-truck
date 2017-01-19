module CoffeeTruck
  module Helpers
    module Security
      include Chef::Mixin::ShellOut
      extend self
      require 'httpi-ntlm'


      def getSecurityStats()

        request = HTTPI::Request.new("https://psdc-pa001gth1v.za.sbicdirectory.com/Cxwebinterface/odata/v1/Projects?$expand=LastScan&$orderby=LastScan/RiskScore%20desc&$top=2")
        request.auth.ntlm("c1592023", "trendweb")
        response = HTTPI.get request
        Chef::Log.warn(response.body)

        t1 = NTLM::Message::Type1.new()


      end

    end
  end

  module DSL

    def getSecurityStats()
      CoffeeTruck::Helpers::Security.getSecurityStats()
    end

  end
end
