require 'chef/mixin/shell_out'
require 'nokogiri'


module CoffeeTruck
  module Helpers
    module Syntax
      include Chef::Mixin::ShellOut
      extend self

      def bumped_pom_version?(path, node)
        change = DeliverySugar::Change.new(node)
        modified_files = change.changed_files
        Chef::Log.error("============\n#{modified_files}\n==============")
        file_changes(change)
        raise RuntimeError, "=========\n#{modified_files}\n========="
      end

      def file_changes(change)
        ref1 = "origin/#{change.pipeline}"
        ref2 = "origin/#{change.patchset_branch}"
        Chef::Log.error("Ref1: #{ref1}\nRef2: #{ref2}\n#{change.workspace_repo}")
        #results = shell_out!("git diff #{ref1} #{ref2}", cwd: change.workspace_repo).stdout.chomp.split("\n")
        results = shell_out!("git show #{ref1}:pom.xml", cwd: change.workspace_repo).stdout.chomp
        xml = Nokogiri::XML(results)
        version = xml.xpath('/xmlns:project/xmlns:version/text()').first.content
        Chef::Log.error("++++++++++++++++
#{version}
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
