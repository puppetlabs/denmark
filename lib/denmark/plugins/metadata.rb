# frozen_string_literal: true

require 'semantic_puppet'

# environments plugin
class Denmark::Plugins::Metadata
  def self.description
    # This is a Ruby squiggle heredoc; just a multi-line string with indentation removed
    <<~DESCRIPTION
      This smell test inspects the module's metadata for signs of something fishy.
      It will also compare that metadata to what exists in the module's git repository.
    DESCRIPTION
  end

  def self.setup
    # run just before evaluating this plugin
  end

  def self.run(mod, repo)
    # return an array of hashes representing any smells discovered
    response = []

    release_date = Date.parse(mod.releases.first.updated_at).to_date
    prev_release = (Date.parse(mod.releases[1].updated_at).to_date unless mod.releases[1].nil?)
    version      = mod.releases.first.version
    changelog    = mod.releases.first.changelog

    repo_metadata   = JSON.parse(repo.file_content('metadata.json') || '{}')
    repo_changelog  = repo.file_content('CHANGELOG.md') || repo.file_content('CHANGELOG')
    latest_tag      = repo.tags.first.name
    latest_tag_date = repo.commit_date(repo.tags.first.commit.sha)

    if (Date.today - release_date) > 365
      response << {
        severity: :green,
        message: 'The most current module release is more than a year old.',
        explanation: "Sometimes a module not seeing regular updates is a sign that it's no longer being maintained.
        You might consider contacting the maintainer to determine the status of the project."
      }
    end

    if (Date.today - release_date) < 15
      response << {
        severity: :green,
        message: 'The latest module release is less than two weeks old.',
        explanation: "Sometimes it's a good idea to let the early adopters shake out the bugs with a new release."
      }
    end

    unless (
        [version, "v#{version}"].include? latest_tag) ||
           (SemanticPuppet::Version.parse(version) <= SemanticPuppet::Version.parse(repo_metadata['version'])
           )
      response << {
        severity: :red,
        message: 'The version released on the Forge is greater than the version in the repository.',
        explanation: 'Forge version numbers cannot be reused, so an attacker might increment the version of a pushed module to induce you to update to their compromised version.
        Validate that the Forge module represents the latest released version from the repository.'
      }
    end

    if changelog != repo_changelog
      response << {
        severity: :green,
        message: "The module changelog on the Forge does not match what's in the repository.",
        explanation: "This is not necessarily a problem. Some developers choose to update the changelog iteratively as they merge pull requests instead of all at release time.
        Still, it's worth double checking."
      }
    end

    unless [version, "v#{version}"].include? latest_tag
      response << {
        severity: :yellow,
        message: 'The version released on the Forge does not match the latest tag in the repo.',
        explanation: 'This sometimes just indicates sloppy release practices, but could indicate a compromised Forge release.'
      }
    end

    if release_date != latest_tag_date
      response << {
        severity: :yellow,
        message: 'The module was not published to the Forge on the same day that the latest release was tagged.',
        explanation: 'This sometimes just indicates sloppy release practices, but could indicate a compromised Forge release.'
      }
    end

    if !prev_release.nil? && (release_date - prev_release) > 365
      response << {
        severity: :green,
        message: 'There was a gap of at least a year between the last two releases.',
        explanation: "A large gap between releases often shows sporadic maintenance.
        This doesn't necessarily indicate anything wrong, but attackers do sometimes target stagnant projects in the hope that they'll be undetected for a longer time period."
      }
    end

    response
  end

  def self.cleanup
    # run just after evaluating this plugin
  end
end
