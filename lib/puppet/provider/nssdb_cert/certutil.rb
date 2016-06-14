Puppet::Type.type(:nssdb_cert).provide(:certutil) do
  commands :certutil => 'certutil'
  has_feature :fileinput
  mk_resource_methods

  def truststring
    [
      @property_hash[:ssltrust].join,
      @property_hash[:smimetrust].join,
      @property_hash[:codetrust].join
    ].join(',')
  end

  def do_create(file=@property_hash[:path])
    if file.nil?
      Tempfile.open("mosdb_cert_#{@resource[:name]}") do |tmpfile|
         tmpfile.write(@property_hash[:content])
         tmpfile.flush
         do_create(tmpfile.path.to_s)
      end
    else
      certutil(["-A", "-d", @resource[:dbpath], "-n", @resource[:alias], "-i", file, "-a", "-t", truststring])
    end
  end

  def create
    @property_hash = {
      name:       @resource[:name],
      ensure:     :present,
      path:       @resource[:path],
      content:    @resource[:content],
      ssltrust:   @resource[:ssltrust],
      smimetrust: @resource[:smimetrust],
      codetrust:  @resource[:codetrust],
    }
  end
  def destroy
    certutil(["-D", "-d", @resource[:dbpath], "-n", @resource[:alias]])
  end
  def exists?
    begin
      certutil(['-L', '-d', @resource[:dbpath]], '-n', @resource[:alias])
      return true
    rescue Puppet::ExecutionFailure => e
      return false
    end
  end

  def self.prefetch(resources)
    by_db = Hash.new { |h, k| h[k] = { } }
    resources.each do |name, res|
      by_db[res[:dbpath]][res['alias']] = res
    end
    by_db.each do |dbpath, dbresources|
      output = certutil(["-L", "-d", dbpath])
      table = output.strip.split("\n\n")[1]
      next if table.nil?
      table.split("\n").each do |line|
        name, ssltrust_s, smimetrust_s, codetrust_s = line.scan(/^(.*\w+)\s+(\w*),(\w*),(\w*)\s*$/).flatten

        next unless dbresources.key?(name)
        res = dbresources[name]

        hash = {
          ensure:     :present,
          ssltrust:   ssltrust_s.split(''),
          smimetrust: smimetrust_s.split(''),
          codetrust:  codetrust_s.split(''),
          content:    certutil(["-L", "-d", dbpath, "-n", name, "-a"]).strip.gsub(/[\n\r]+/, "\n"),
        }
        unless res[:path].nil?
          begin
            newdata = File.read(res[:path]).strip.gsub(/[\n\r]+/, "\n")
            if hash[:content].to_s.eql?(newdata.to_s)
              hash[:path] = res[:path]
            else
              hash[:path] = ""
            end
          rescue
            hash[:path] = ""
          end
        end
        dbresources[name].provider = new(hash)
      end
    end
  end

  def flush
    destroy if exists?
    do_create
  end
end
