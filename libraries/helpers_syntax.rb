require 'chef/mixin/shell_out'
require 'nokogiri'


module CoffeeTruck
  module Helpers
    module Syntax
      include Chef::Mixin::ShellOut
      extend self

      def bumped_pom_version?(path, node)
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

      def ensure_snapshot?(path,node)
        return true if node['delivery']['change']['stage'] == 'build'
        cwd = node['delivery']['workspace']['repo']
        path = "#{cwd}/pom.xml"
        doc = ::File.open(path) { |f| Nokogiri::XML(f) }
        doc.xpath('/xmlns:project/xmlns:version/text()').first.content.end_with?("-SNAPSHOT")
      end
    end
  end

  module DSL

    def bumped_pom_version?(path)
      CoffeeTruck::Helpers::Syntax.bumped_pom_version?(path, node)
    end

    def ensure_snapshot?(path)
      CoffeeTruck::Helpers::Syntax.ensure_snapshot?(path,node)
    end
  end
end
