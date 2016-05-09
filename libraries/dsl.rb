require_relative 'helpers_unit'
require_relative 'helpers_syntax'
require_relative 'helpers_publish'

Chef::Recipe.send(:include, CoffeeTruck::DSL)
Chef::Resource.send(:include, CoffeeTruck::DSL)
Chef::Provider.send(:include, CoffeeTruck::DSL)
