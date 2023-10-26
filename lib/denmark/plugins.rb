# frozen_string_literal: true

require 'little-plugger'

# metrics class
class Denmark::Plugins
  extend LittlePlugger(path: 'denmark/plugins', module: Denmark::Plugins)

  def initialize(options)
    if options[:enable]
      disable = Denmark::Plugins.plugins.keys - options[:enable].map(&:to_sym)
      options[:disable] ||= []
      options[:disable].concat disable
    end
    Denmark::Plugins.disregard_plugins(*options[:disable])
    Denmark::Plugins.initialize_plugins
  end

  def list
    str = "                    Available smell test plugins\n"
    str += "                 ===============================\n\n"
    Denmark::Plugins.plugins.each do |name, plugin|
      str += name.to_s
      str += "\n--------\n"
      str += plugin.description.strip
      str += "\n\n"
    end
    str
  end

  def run(mod, repo)
    results = []
    Denmark::Plugins.plugins.each do |_name, plugin|
      plugin.setup
      results.concat plugin.run(mod, repo)
      plugin.cleanup
    end
    results
  end
end
