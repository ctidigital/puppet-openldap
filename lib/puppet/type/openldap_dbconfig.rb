Puppet::Type.newtype(:openldap_dbconfig) do

  ensurable

  newparam(:name) do
  end

  newparam(:suffix, :namevar => true) do
  end

  newparam(:target, :namevar => true) do
  end

  newparam(:value, :namevar => true) do
  end

  newproperty(:position) do
  end

  def self.title_patterns
    [
      [
        /^((\S+)\s(.+)?\s+on\s+(.+))$/,
        [
          [ :name, lambda{|x| x} ],
          [ :target, lambda{|x| x} ],
          [ :value, lambda{|x| x} ],
          [ :suffix,  lambda{|x| x} ],
        ],
      ],
      [
        /^((\S+)\s+on\s+(.+))$/,
        [
          [ :name, lambda{|x| x} ],
          [ :target, lambda{|x| x} ],
          [ :suffix,  lambda{|x| x} ],
        ],
      ],
      [
        /(.*)/,
        [
          [ :name, lambda{|x| x} ],
        ],
      ],
    ]
  end

  autorequire(:openldap_database) do
    [ value(:suffix) ]
  end

end
