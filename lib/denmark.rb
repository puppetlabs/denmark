# frozen_string_literal: true

require 'json'
require 'colorize'
require 'httpclient'
require 'puppet_forge'
require 'denmark/plugins'
require 'denmark/repository'
require 'denmark/monkeypatches'

class Denmark
  PuppetForge.user_agent = "Denmark Module Smell Checker/#{Denmark::VERSION}"

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
    slug.sub!('/', '-')
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

  def self.generate_report(data)
    if data.empty?
      puts "Congrats, no smells discovered"
    else
      puts
      [:red, :orange, :yellow, :green].each do |severity|
        alerts = data.select {|i| i[:severity] == severity}
        next unless alerts.size > 0

        puts "[#{severity.upcase}] alerts:".colorize(severity)
        alerts.each do |alert|
          puts "  #{alert[:message]}"
          puts "    > #{alert[:explanation]}" if @options[:detail]
        end
        puts
      end
    end
  end


  def self.info(slug)
    mod = PuppetForge::Module.find(slug)

    puts mod.owner.username
    puts mod.owner.display_name
    puts mod.current_release.version
    puts mod.current_release.created_at
    puts mod.current_release.changelog
    puts mod.current_release.reference
    puts mod.current_release.license
    puts mod.homepage_url
    puts mod.current_release.metadata['project_page']
    puts mod.current_release.metadata['source']
    puts mod.issues_url

    client = Octokit::Client.new
    repo   = Octokit::Repository.from_url(mod.homepage_url, options)

require 'pry'
binding.pry

    puts client.pull_requests(repo)
    puts client.list_issues(repo)
  end


  def github_client
    @token ||= ENV['GITHUB_TOKEN'] || `git config --global github.token`.chomp

    if @token.empty?
      puts "You need to generate a GitHub token:"
      puts "\t * https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line"
      puts "\t * git config --global github.token <token>"
      puts
      puts "Export that as the `GITHUB_TOKEN` environment variable or put it in your ~/.gitconfig."
      exit 1
    end

    begin
      client = Octokit::Client.new(:access_token => @token)
    rescue => e
      puts "Github login error: #{e.message}"
      exit 1
    end

    client
  end

end

