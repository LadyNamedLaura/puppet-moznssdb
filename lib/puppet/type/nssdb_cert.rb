Puppet::Type.newtype(:nssdb_cert) do
  ensurable
  feature :fileinput, "read cert from local file"

  def self.mungetrust(value)
    trustmap = {
      'prohibited' => 'p',
      'peer'       => 'P',
      'ca'         => 'c',
      'clientca'   => 'T',
      'serverca'   => 'C',
      'usercert'   => 'u',
      'warning'    => 'w',
      'step-up'    => 'g'
    }
    if value.is_a?(String) && value.length > 1
      trustmap[value]
    else
      value
    end
  end

  newparam(:name, :namevar => true) do
  end

  newparam(:alias) do
    isrequired
  end
  newparam(:dbpath) do
    isrequired
    desc "The path to the database."
  end


  newproperty(:ssltrust, :array_matching => :all) do
    newvalues(/[pPcTCuwg]?/)
    munge do |value|
      Puppet::Type::Nssdb_cert.mungetrust(value)
    end
    def insync?(is)
      is.sort == should.sort || is.sort.reject { |c| c == 'u'} == should.sort
    end
    defaultto Array.new
  end
  newproperty(:smimetrust, :array_matching => :all) do
    newvalues(/[pPcTCuwg]?/)
    munge do |value|
      Puppet::Type::Nssdb_cert.mungetrust(value)
    end
    def insync?(is)
      is.sort == should.sort || is.sort.reject { |c| c == 'u'} == should.sort
    end
    defaultto Array.new
  end
  newproperty(:codetrust, :array_matching => :all) do
    newvalues(/[pPcTCuwg]?/)
    munge do |value|
      Puppet::Type::Nssdb_cert.mungetrust(value)
    end
    def insync?(is)
      is.sort == should.sort || is.sort.reject { |c| c == 'u'} == should.sort
    end
    defaultto Array.new
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
    self.fail("ssltrust should be an array") unless @parameters[:ssltrust].value.is_a?(Array)
    self.fail("smimetrust should be an array") unless @parameters[:smimetrust].value.is_a?(Array)
    self.fail("codetrust should be an array") unless @parameters[:codetrust].value.is_a?(Array)

    provider.validate if provider.respond_to?(:validate)
  end
end
