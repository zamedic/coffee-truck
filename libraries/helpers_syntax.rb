module CoffeeTruck
  module Helpers
    module Syntax
      extend self

      def bumped_version?(path, node)
        change = DeliverySugar::Change.new(node)
        modified_files = change.changed_files
        Chef::Log.error("============\n#{modified_files}\n==============")
        raise RuntimeError, "=========\n#{modified_files}\n=========")
      end
    end
  end

  module DSL

    def bumped_version?(path)
      CoffeeTruck::Helpers::Syntax.bumped_version?(path, node)
    end
  end
end
