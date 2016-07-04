Puppet::Type.newtype(:nssdb) do
  ensurable

  newparam(:path, :namevar => true) do
  end
  autorequire(:file) do
    [@parameters[:path].value]
  end
end
