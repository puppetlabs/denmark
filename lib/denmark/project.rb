# frozen_string_literal: true

class Denmark::Project
  def initialize(name, type)
    @name = name
    @type = type

    case @type
    when 'puppet'
      require 'puppet_forge'
      PuppetForge.user_agent = "Denmark Module Smell Checker/#{Denmark::VERSION}"

      begin
        @wrapper = PuppetForge::Module.find(name)
      rescue Faraday::BadRequestError, Faraday::ResourceNotFound
        raise "The module `#{name}` was not found on the Puppet Forge."
      end
    else
      raise "Unsupported project type: '#{@type}'"
    end

  end

  def homepage_url
    @wrapper.homepage_url
  end

  def releases
    @wrapper.releases
  end
end
