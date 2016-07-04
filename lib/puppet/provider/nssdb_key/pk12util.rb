require 'rubygems' if RUBY_VERSION < '1.9.0' && Puppet.features.rubygems?
require 'openssl' if Puppet.features.openssl?

Puppet::Type.type(:nssdb_key).provide(:pk12util) do
  confine :feature => :openssl
  commands :certutil => 'certutil'
  commands :pk12util => 'pk12util'
  has_feature :fileinput
  mk_resource_methods

  def genpk12(pass = '')
    rawcert = certutil(["-L", "-d", @resource[:dbpath], "-n", @resource[:alias], "-a"]).strip.gsub(/[\n\r]+/, "\n")
    cert = OpenSSL::X509::Certificate.new(rawcert)

    if @property_hash[:path]
      pkey = OpenSSL::PKey.read(File.new(@property_hash[:path]))
    else
      pkey = OpenSSL::PKey.read(@property_hash[:content])
    end
    OpenSSL::PKCS12::create(pass, @resource[:alias], pkey, cert)
  end

  def do_create
    pass = SecureRandom.hex
    pk12 = genpk12(pass)

    Tempfile.open("mosdb_key_#{@resource[:name]}") do |tmpfile|
      tmpfile.write(pk12.to_der)
      tmpfile.flush
      pk12util(["-i", tmpfile.path.to_s, "-d", @resource[:dbpath], "-W", pass])
      len = tmpfile.pos
      tmpfile.pos = 0
      tmpfile.write("0"*len)
      tmpfile.flush
    end
  end

  def create
    @property_hash = {
      name:       @resource[:name],
      ensure:     :present,
      path:       @resource[:path],
      content:    @resource[:content],
    }
  end
  def destroy
    certutil(["-F", "-d", @resource[:dbpath], "-n", @resource[:alias]])
  end
  def exists?
    begin
      certutil(['-K', '-d', @resource[:dbpath]], '-n', @resource[:alias])
      return true
    rescue Puppet::ExecutionFailure => e
      return false
    end
  end

  def self.prefetch(resources)
    by_db = Hash.new { |h, k| h[k] = { } }
    resources.each do |name, res|
      by_db[res[:dbpath]][res[:alias]] = res
    end
    by_db.each do |dbpath, dbresources|
      begin
        output = certutil(["-K", "-d", dbpath])
      rescue Puppet::ExecutionFailure
        next
      end
      output.split("\n").each do |line|
        keytype, csum, name = line.scan(/<.*>\s+(\w+)\s+([0-9a-f]{40})\s+(\w+(.*\w+)*)/).flatten

        next unless dbresources.key?(name) && keytype
        res = dbresources[name]

        pk12 = nil
        Tempfile.open("mosdb_key_#{name}") do |tmpfile|
          pass = SecureRandom.hex
          pk12util(["-d", dbpath, "-W", pass, "-n", name, "-o", tmpfile.path.to_s])
          pk12data = tmpfile.read
          pk12     = OpenSSL::PKCS12::new(pk12data,pass)
        end
        hash = {
          ensure: :present,
        }

        unless res[:path].nil?
          hash[:path] = ''
          begin
            newdata = File.read(res[:path]).strip.gsub(/[\n\r]+/, "\n")
            if pk12.key.to_s.strip == newdata
              hash[:path] = res[:path]
            end
          rescue
          end
        else
          hash[:content] = pk12.key.to_s
        end
        res.provider = new(hash)
      end
    end
  end

  def flush
    #destroy if exists?
    do_create
  end
end
