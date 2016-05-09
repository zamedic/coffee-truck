require 'chef/mixin/shell_out'
require 'nokogiri'


module CoffeeTruck
  module Helpers
    module Syntax
      include Chef::Mixin::ShellOut
      extend self

      def bumped_pom_version?(path, node)
        change = DeliverySugar::Change.new(node)
        ref_old = "origin/#{change.pipeline}"
        ref_new = "origin/#{change.patchset_branch}"
        old_version, new_version = [ref_old, ref_new].each do |ref|
          pom = shell_out!("git show #{ref}:pom.xml", cwd: change.workspace_repo).stdout.chomp
          Nokogiri::XML(pom).xpath('/xmlns:project/xmlns:version/text()').first.content
        end
        Chef::Log.error("++++++++++++++++
#{old_version}
#{new_version}
++++++++++++++")
      end
    end
  end

  module DSL

    def bumped_pom_version?(path)
      CoffeeTruck::Helpers::Syntax.bumped_pom_version?(path, node)
    end
  end
end
