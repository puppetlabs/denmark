# frozen_string_literal: true

require 'json'
require 'httpclient'
require 'puppet_forge'

class Denmark
  require 'denmark/plugins'
  require 'denmark/repository'
  require 'denmark/monkeypatches'
  require 'denmark/version'

  PuppetForge.user_agent = "Denmark Module Smell Checker/#{Denmark::VERSION}"
  @config = {}

  def self.config=(arg)
    raise "Requires a Hash to set config, not a #{arg.class}" unless arg.is_a? Hash
    @config = arg
  end
  def self.config(*args)
    if args.empty?
      @config
    else
      @config.dig(*args)
    end
  end


  def self.list(options)
    puts
    puts Denmark::Plugins.new(options).list
  end

  def self.evaluate(slug, options)
    @options = options
    slug = resolve_slug(slug)

    begin
      mod = PuppetForge::Module.find(slug)
    rescue Faraday::BadRequestError, Faraday::ResourceNotFound
      raise "The module `#{slug}` was not found on the Puppet Forge."
    end

    repo = Denmark::Repository.new(mod.homepage_url)
    data = Denmark::Plugins.new(options).run(mod, repo)

    case options[:format]
    when 'json'
      puts JSON.pretty_generate(data)
    when 'human'
      generate_report(data)
    else
      raise 'unknown format'
    end
  end

  def self.resolve_slug(path)
    begin
      if path.nil?
        path = JSON.parse(File.read('metadata.json'))['name']
      elsif File.directory?(path)
        path = JSON.parse(File.read("#{path}/metadata.json"))['name']
      elsif path.end_with?('metadata.json')
        path = JSON.parse(File.read(path))['name']
      end
    rescue Errno::ENOENT => e
      raise "Cannot load metadata from '#{path}'. Pass this tool the name of a module, or the local path to a module."
    end

    # if we get this far, assume it's the name of a module and normalize it
    path.sub('/', '-')
  end

  def self.generate_report(data)
    if data.empty?
      puts "Congrats, no smells discovered"
    else
      puts
      [:red, :orange, :yellow, :green].each do |severity|
        alerts = data.select {|i| i[:severity] == severity}
        next unless alerts.size > 0

        puts "[#{severity.upcase}] alerts:".color_name(severity)
        alerts.each do |alert|
          puts "  #{alert[:message]}"
          puts "    > #{alert[:explanation]}" if @options[:detail]
        end
        puts
      end
    end
  end

end

