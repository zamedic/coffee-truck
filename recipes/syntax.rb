include_recipe 'delivery-truck::syntax'


# If we changed a cookbook but didn't bump the version than the build
# phase will fail when trying to upload to the Chef Server.
unless bumped_pom_version?(node['delivery']['workspace']['repo'])
end 

raise RuntimeError, "Artefact versino unchanged"
#  # Run `knife cookbook test` against the modified cookbook
#  execute "syntax_check_#{cookbook.name}" do
#    command "knife cookbook test -o #{cookbook.path} -a"
#  end 
