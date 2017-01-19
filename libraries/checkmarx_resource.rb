class Chef
  class Resource
    class Checkmarx < Chef::Resource::LWRPBase
      resource_name :checkmarx

      actions :update_demoncat
      default_action :update_demoncat if defined?(default_action)

      attribute :name, :kind_of => String, required: true, name_attribute: true

    end
  end
end
