# frozen_string_literal: true

class GemReleaseWrapper
  def initialize(data)
    @data = data
  end

  def updated_at
    @data['created_at']
  end

  def version
    @data['number']
  end

  def changelog
    nil
  end
end

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
    when 'gem'
      require 'gems'
      info = Gems.info(name)
      versions = Gems.versions(name)
      wrapped_versions = []
      versions.each do |version|
        wrapped_versions << GemReleaseWrapper.new(version)
      end
      @wrapper = {'info': info, 'versions': wrapped_versions}
    when 'python'
      require 'denmark/pypi'
      @wrapper = Denmark::Pypi.new(name)
    else
      raise "Unsupported project type: '#{@type}'"
    end

  end

  def homepage_url
    case @type
    when 'puppet'
      @wrapper.homepage_url
    when 'gem'
      @wrapper[:info]['source_code_uri'] || @wrapper[:info]['homepage_uri']
    when 'python'
      @wrapper.scm_url
    end
  end

  def releases
    case @type
    when 'puppet', 'python'
      @wrapper.releases
    when 'gem'
      @wrapper[:versions]
    end
  end
end
