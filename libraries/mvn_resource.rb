class Chef
  class Resource
    class Mvn < Chef::Resource::LWRPBase
      resource_name :mvn

      actions :unit, :sonar, :upload
      default_action :unit if defined?(default_action)

      attribute :name, :kind_of => String, required: true, name_attribute: true
      attribute :cwd, :kind_of => String
      attribute :settings, :kind_of => String
      attribute :definitions, :kind_of => Hash, default: Hash.new
      attribute :environment, :kind_of => Hash, default: Hash.new
    end
  end
end
