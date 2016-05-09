module CoffeeTruck
  module Helpers
    module Syntax
      extend self

      def bumped_pom_version?(path, node)
        change = DeliverySugar::Change.new(node)
        modified_files = change.changed_files
        Chef::Log.error("============\n#{modified_files}\n==============")
        file_changes
        raise RuntimeError, "=========\n#{modified_files}\n========="
      end

      def file_changes()
        ref1 = "origin/#{@pipeline}"
        ref2 = "origin/#{@patchset_branch}"
        results = shell_out!("git diff --name-only #{ref1} #{ref2}", cwd: @workspace_repo).stdout.chomp.split("\n")
        Chef::Log.error("++++++++++++++++\n#{results}\n++++++++++++++++++")
      end
    end
  end

  module DSL

    def bumped_pom_version?(path)
      CoffeeTruck::Helpers::Syntax.bumped_pom_version?(path, node)
    end
  end
end
