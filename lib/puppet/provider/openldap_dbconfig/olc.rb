require 'tempfile'

Puppet::Type.type(:openldap_dbconfig).provide(:olc) do

  # TODO: Use ruby bindings (can't find one that support IPC)

  defaultfor :osfamily => :debian, :osfamily => :redhat

  commands :slapcat => 'slapcat', :ldapmodify => 'ldapmodify'

  mk_resource_methods

  def self.instances(suffix)
    db = slapcat(
      '-b',
      'cn=config',
      '-H',
      'ldap:///???(&(objectClass=olcDatabaseConfig)(|(objectClass=olcBdbConfig)(objectClass=olcHdbConfig)(objectClass=olcMdbConfig))(olcSuffix=#{suffix}))'
    ).split("\n\n").collect do |para|
      
      para.gsub("\n ","")split("\n").select{|e| e =~ /^olc/}.collect do |line|
      name, value = line.split(': ')
      # initialize @property_hash
      new(
        :name   => name[3, name.length],
        :ensure => :present,
        :value  => value
      )
    end
  end

  def self.prefetch(resources)
    items = instances(resources[:suffix])
    resources.keys.each do |name|
      if provider = items.find{ |item| item.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    t = Tempfile.new('openldap_db_config')
    t << "dn: cn=config\n"
    t << "add: olc#{resource[:name]}\n"
    t << "olc#{resource[:name]}: #{resource[:value]}\n"
    t.close
    Puppet.debug(IO.read t.path)
    begin
      ldapmodify('-Y', 'EXTERNAL', '-H', 'ldapi:///', '-f', t.path)
    rescue Exception => e
      raise Puppet::Error, "LDIF content:\n#{IO.read t.path}\nError message: #{e.message}"
    end
    @property_hash[:ensure] = :present
  end

  def destroy
    t = Tempfile.new('openldap_db_config')
    t << "dn: cn=config\n"
    t << "delete: olc#{name}\n"
    t.close
    Puppet.debug(IO.read t.path)
    begin
      ldapmodify('-Y', 'EXTERNAL', '-H', 'ldapi:///', '-f', t.path)
    rescue Exception => e
      raise Puppet::Error, "LDIF content:\n#{IO.read t.path}\nError message: #{e.message}"
    end
    @property_hash.clear
  end

  def value=(value)
    t = Tempfile.new('openldap_db_config')
    t << "dn: cn=config\n"
    t << "replace: olc#{name}\n"
    t << "olc#{name}: #{value}\n"
    t.close
    Puppet.debug(IO.read t.path)
    begin
      ldapmodify('-Y', 'EXTERNAL', '-H', 'ldapi:///', '-f', t.path)
    rescue Exception => e
      raise Puppet::Error, "LDIF content:\n#{IO.read t.path}\nError message: #{e.message}"
    end
    @property_hash[:value] = value
  end

end
