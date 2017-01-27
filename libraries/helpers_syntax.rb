require 'chef/mixin/shell_out'
require 'nokogiri'


module CoffeeTruck
  module Helpers
    module Syntax
      include Chef::Mixin::ShellOut
      extend self

      def bumped_pom_version?(node)
        return true if node['delivery']['change']['stage'] == 'build'
        change = DeliverySugar::Change.new(node)
        ref_old = "origin/#{change.pipeline}"
        ref_new = "origin/#{change.patchset_branch}"
        old_version, new_version = [ref_old, ref_new].map do |ref|
          pom = shell_out!("git show #{ref}:pom.xml", cwd: change.workspace_repo).stdout.chomp
          Nokogiri::XML(pom).xpath('/xmlns:project/xmlns:version/text()').first.content.split('-').first
        end
        Gem::Version.new(old_version) < Gem::Version.new(new_version)
      end

      def ensure_snapshot?(node)
        return true if node['delivery']['change']['stage'] == 'build'
        get_current_version(node).end_with?("-SNAPSHOT")
      end

      def get_current_version(node)
        cwd = node['delivery']['workspace']['repo']
        path = "#{cwd}/pom.xml"
        doc = ::File.open(path) { |f| Nokogiri::XML(f) }
        doc.xpath('/xmlns:project/xmlns:version/text()').first.content
      end

      def java_changes?(node,changes)
        Chef::Log.warn(changes)
        changes.each do |file|
          if (!file.start_with?('cookbooks/','.delivery/','.gitignore'))
            return true
          end
        end
        return false

      end
    end
  end

  module DSL

    def bumped_pom_version?()
      CoffeeTruck::Helpers::Syntax.bumped_pom_version?(node)
    end

    def ensure_snapshot?()
      CoffeeTruck::Helpers::Syntax.ensure_snapshot?(node)
    end

    def pom_version()
      CoffeeTruck::Helpers::Syntax.get_current_version(node)
    end

    def pom_version_no_snapshot()
      CoffeeTruck::Helpers::Syntax.get_current_version(node).split('-').first
    end

    def java_changes?(changes)
      CoffeeTruck::Helpers::Syntax.java_changes?(node,changes)
    end
  end
end
