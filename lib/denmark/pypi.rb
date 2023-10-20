# frozen_string_literal: true

require 'httparty'

class Denmark::PypiRelease
  def initialize(version, data)
    @version = version
    @data = data
  end

  def updated_at
    @data['upload_time']
  end

  def version
    @version
  end

  def changelog
    nil
  end
end

class Denmark::Pypi
  def initialize(name)
    @name = name
    url = "https://pypi.org/pypi/#{name}/json"
    @data = HTTParty.get(url).parsed_response
  end

  def version
    @data['info']['version']
  end

  def scm_url
    @data['info'].fetch('project_urls', {}).fetch('Source', nil) || @data['info'].fetch('project_urls', {}).fetch('Homepage', nil) || @data['info'].fetch('home_page', nil)
  end

  def releases
    @releases = []
    @data['releases'].each do |version, data|
      release = Denmark::PypiRelease.new(version, data.select { |d| d['packagetype'] == 'sdist' }.first)
      @releases << release
    end
    # this in theory needs a sort_by on the version attribute, with a sorter that understands python versioning
    @releases.reverse
  end
end
