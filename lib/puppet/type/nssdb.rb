Puppet::Type.newtype(:nssdb) do
  ensurable

  newparam(:path, :namevar => true) do
  end
#  newproperty(:password) do
#    defaultto ""
#  end
end
