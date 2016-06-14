Puppet::Type.type(:nssdb).provide(:certutil) do
  commands :certutil => 'certutil'

  def create
    certutil(["-N", "-d", @resource[:path], "--empty-password"])
  end
  def destroy
    ["cert8.db", "key3.db", "secmod.db"].each do |file|
      File.unlink(@resource[:path]+"/"+file)
    end
  end
  def exists?
    begin
      certutil(['-L', '-d', @resource[:path]])
      return true
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("#get_proxy_bypass_domains had an error -> #{e.inspect}")
      return false
    end
  end
end
