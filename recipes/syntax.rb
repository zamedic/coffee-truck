include_recipe 'delivery-truck::syntax'


#  # If we changed a cookbook but didn't bump the version than the build
#  # phase will fail when trying to upload to the Chef Server.
#  unless bumped_version?(cookbook.path)
#    raise RuntimeError, "The #{cookbook.name} cookbook was modified " \
#                        "but the version was not updated in the " \
#                        "metadata file."
#  end 
#
#  # Run `knife cookbook test` against the modified cookbook
#  execute "syntax_check_#{cookbook.name}" do
#    command "knife cookbook test -o #{cookbook.path} -a"
#  end 
