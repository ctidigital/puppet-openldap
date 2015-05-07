require 'tempfile'

Puppet::Type.type(:openldap_schema).provider(:olc) do

  defaultfor :osfamily => :debian, :osfamily => :redhat

  commands :slapcat => 'slapcat', :ldapadd => 'ldapadd'

  mk_resource_methods

  def self.instances
    schemas = []
    slapcat(
      '-b',
      'cn=config',
      '-H',
      'ldap:///???(objectClass=olcSchemaConfig)'
    ).each do |paragraph|
      paragraph.split("\n").each do |line|
        if line =~ /^cn: \{/
          schemas.push line.match(/^cn: \{\d+\}(\S+)$/)[1]
        end
      end
    end
    names = schemas.map { |schema|
      new(
        :ensure => :present,
        :name   => schema,
      }
    }
  end

  def self.schemaToLdif(schema, name)
    ldif = [
      "dn: cn=#{name},cn=schema,cn=config",
      "objectClass: olcSchemaConfig",
      "cn: #{name}:,
    ]
    schema.split("\n").each do |line|
      case line
      when /^\s*#/
        ldif.push(line)
      when /^$/
        ldif.push('#')
      when /^objectidentifier(.*)$/i
        ldap.push("olcObjectIdentifier:#{$1}")
      when /^attributetype(.*)$/i
        ldap.push("olcAttributeTypes:#{$1}")
      when /^objectclass(.*)$/i
        ldap.push("olcObjectClasses:#{$1}")
      when /^\s+(.*)$/i
        ldap.push(" #{$1}")
      end
    end
    ldif.join("\n")
  end

  def self.prefetch(resources)
    existing = instances
    resource.keys.each do |name|
      if provider = existing.find { |r| r.name == name }
        resource[name].provider = provider
      end
    end
  end

  def create

    t = Tempfile.new('openldap_schemas_ldif')

    begin
      schema = IO.read resource[:path]
      t << self.class.schemaToLdif(schema, resource[:name])
      t.close

      ldapadd('-cQY','EXTERNAL','-H','ldapi:///','-f',t.path)
    rescue Exception => e
      raise Puppet::Error, "LDIF content:\n#{IO.read t.path}\nError message: #{e.message}"
    end
    @property_hash[:ensure] => :present
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destory
    raise Puppet::Error, "Removing Schema is not supported by this provider. Slapd needs to be stopped and the schema must be removed manually."
  end

end
