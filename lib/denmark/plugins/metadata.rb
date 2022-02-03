# frozen_string_literal: true

# environments plugin
class Denmark::Plugins::Metadata
  def self.description
    # This is a Ruby squiggle heredoc; just a multi-line string with indentation removed
    <<~DESCRIPTION
      This smell test inspects the module's metadata for signs of something fishy. It will also compare
      that metadata to what exists in the module's git repository.
    DESCRIPTION
  end
  def self.setup
    # run just before evaluating this plugin
  end

  def self.run(mod, repo)
    # return an array of hashes representing any smells discovered
    response = Array.new

    release_date = Date.parse(mod.releases.first.updated_at).to_date
    prev_release = Date.parse(mod.releases[1].updated_at).to_date
    version      = mod.releases.first.version
    changelog    = mod.releases.first.changelog

    repo_metadata   = JSON.parse(repo.file_content('metadata.json'))
    repo_changelog  = repo.file_content('CHANGELOG.md') || repo.file_content('CHANGELOG')
    latest_tag      = repo.tags.first.name
    latest_tag_date = repo.commit_date(repo.tags.first.commit.sha)

    if (Date.today - release_date) > 365
      response << {
        severity: :yellow,
        message: "The most current module release is more than a year old.",
        explanation: "Sometimes when issues are not responded to, it means that the project is no longer being maintained. You might consider contacting the maintainer to determine the status of the project.",
      }
    end

    if version != repo_metadata[:version]
      response << {
        severity: :red,
        message: "The version released on the Forge does not match the version in the repository.",
        explanation: "Validate that the Forge release is not compromised and is the latest released version.",
      }
    end

    if changelog != repo_changelog
      response << {
        severity: :green,
        message: "The module changelog on the Forge does not match what's in the repository.",
        explanation: "This is not necessarily a problem. Some developers choose to update the changelog iteratively as they merge pull requests instead of all at release time. Still, it's worth double checking.",
      }
    end

    if version != latest_tag
      response << {
        severity: :yellow,
        message: "The version released on the Forge does not match the latest tag in the repo.",
        explanation: "This sometimes just indicates sloppy release practices, but could indicate a compromised Forge release.",
      }
    end

    if release_date != latest_tag_date
      response << {
        severity: :yellow,
        message: "The module was not published to the Forge on the same day that the latest release was tagged.",
        explanation: "This sometimes just indicates sloppy release practices, but could indicate a compromised Forge release.",
      }
    end

    if (release_date - prev_release) > 365
      response << {
        severity: :green,
        message: "There was a gap of at least a year between the last two releases.",
        explanation: "A large gap between releases often shows sporadic maintenance. This is not always bad.",
      }
    end

    response
  end

  def self.cleanup
    # run just after evaluating this plugin
  end
end
