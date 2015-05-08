require 'tempfile'

Puppet::Type.type(:openldap_dbconfig).provide(:olc) do

  # TODO: Use ruby bindings (can't find one that support IPC)

  defaultfor :osfamily => :debian, :osfamily => :redhat

  commands :slapcat => 'slapcat', :ldapmodify => 'ldapmodify'

  mk_resource_methods

  def self.instances(suffix)
    i = []
    Puppet.debug "dbconfig instances for #{suffix}\n"
    db = slapcat(
      '-b',
      'cn=config',
      '-H',
      "ldap:///???(&(objectClass=olcDatabaseConfig)(|(objectClass=olcBdbConfig)(objectClass=olcHdbConfig)(objectClass=olcMdbConfig))(olcSuffix=#{suffix}))"
#      "ldap:///???(&(objectClass=olcDatabaseConfig)(|(objectClass=olcBdbConfig)(objectClass=olcHdbConfig)(objectClass=olcMdbConfig)))"
    ).split("\n\n").collect do |para|
      dn = nil
      para.gsub("\n ","").split("\n").collect do |line|
        case line
        when /^dn: /
          dn = line.split(": ")[1]
        when /^olc/
          name, value = line.split(': ')
          Puppet.debug "dbconfig found #{name} = '#{value}\n"
          # initialize @property_hash
          i << new(
            :name   => name[3, name.length],
            :ensure => :present,
            :value  => value
          )
        end
      end
    end
    i
  end

  def self.prefetch(resources)
    items = {}
    resources.keys.each do |n|
      sffx = resources[n][:suffix]
      if ! items.has_key?(sffx)
        items[sffx] = instances(sffx)
      end
    end
    resources.keys.each do |name|
      sffx = resources[name][:suffix]
      if provider = items[sffx].find{ |item| item.name == name }
        resources[name].provider = provider
      end
    end
  end

  def getDn(suffix)
    slapcat(
      '-b',
      'cn=config',
      '-H',
      "ldap:///???(olcSuffix=#{suffix})"
    ).split("\n").collect do |line|
      if line =~ /^dn: /
        return line.split(' ')[1]
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    t = Tempfile.new('openldap_db_config')
    t << "dn: #{getDn(resource[:suffix])}\n"
    t << "add: olc#{resource[:target]}\n"
    t << "olc#{resource[:target]}: #{resource[:value]}\n"
    t.close
    Puppet.debug "dbconfig create resource\n"
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
    t << "dn: #{getDn(suffix)}\n"
    t << "delete: olc#{target}\n"
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
    t << "dn: #{getDn(suffix)}\n"
    t << "replace: olc#{target}\n"
    t << "olc#{target}: #{value}\n"
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
