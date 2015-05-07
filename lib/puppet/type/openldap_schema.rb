Puppet::Type.newtype(:openldap_schema) do
  @doc = "Manages OpenLDAP schemas."

  ensurable

  newparam(:name) do
    desc "The Schema Name - default namevar"
  end

  newparam(:path) do
    desc "The location of the schema file"
  end
end
