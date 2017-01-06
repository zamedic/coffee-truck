require_relative 'helpers_unit'
require_relative 'helpers_syntax'
require_relative 'helpers_publish'
require_relative 'helpers_lint'
require_relative 'helpers_functional'

Chef::Recipe.send(:include, CoffeeTruck::DSL)
Chef::Resource.send(:include, CoffeeTruck::DSL)
Chef::Provider.send(:include, CoffeeTruck::DSL)
