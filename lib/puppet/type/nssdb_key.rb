Puppet::Type.newtype(:nssdb_key) do
  ensurable
  feature :fileinput, "read cert from local file"

  newparam(:name, :namevar => true) do
  end

  newparam(:alias) do
    isrequired
  end
  newparam(:dbpath) do
    isrequired
    desc "The path to the database."
  end

  newproperty(:path, :required_features => %w{fileinput}) do
  end
  newproperty(:content) do
    munge do |value|
      value.strip.gsub(/[\n\r]+/, "\n")
    end
  end

  validate do
    if @parameters[:content].nil? == @parameters[:path].nil?
      self.fail("provide one of content or path")
    end

    provider.validate if provider.respond_to?(:validate)
  end
  autorequire(:nssdb_cert) do
    [@parameters[:name]]
  end
end
