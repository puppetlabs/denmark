# frozen_string_literal: true

# environments plugin
class Denmark::Plugins::Timeline
  def self.description
    # This is a Ruby squiggle heredoc; just a multi-line string with indentation removed
    <<~DESCRIPTION
      This smell test infers trends a module base on its timeline of issues and commits and whatnot.
    DESCRIPTION
  end

  def self.setup
    # run just before evaluating this plugin
  end

  def self.run(_mod, repo)
    # return an array of hashes representing any smells discovered
    response = []

    unreleased  = repo.commits_since_tag.size
    new_issues  = repo.issues_since_tag.size
    taggers     = repo.committers(repo.tags)
    last_tagger = taggers.shift

    unsigned_commits = repo.commits.percent_of { |i| !repo.verified(i) }
    unsigned_tags = repo.tags.percent_of { |i| !repo.verified(i) }

    unless taggers.include? last_tagger
      response << {
        severity: :yellow,
        message: "The last tag was pushed by #{last_tagger}, who has not tagged any other release.",
        explanation: "This often indicates that a project has recently changed owners.
        Check to ensure you still know who's maintaining the project."
      }
    end

    unless repo.verified(repo.tags.first)
      response << {
        severity: :yellow,
        message: 'The last tag was not verified.',
        explanation: "Many authors don't bother to sign their tags. This means you have no way to ensure who creates them."
      }
    end

    # this smell would be more accurate if we weighted more recent commits
    if (25..75).cover? unsigned_commits
      response << {
        severity: :green,
        message: "#{unsigned_commits}% of the commits in this repo are not signed.",
        explanation: 'The repository is using signed commits, but some of the contributions are unverified.'
      }
    end

    # this smell would be more accurate if we weighted more recent tags
    if (15..85).cover? unsigned_tags
      response << {
        severity: :green,
        message: "#{unsigned_tags}% of the tags in this repo are not signed.",
        explanation: 'The repository is using signed tags, but a significant number are unverified.'
      }
    end

    if (unsigned_tags > 85) && !repo.verified(repo.tags.first)
      response << {
        severity: :red,
        message: 'Most tags in this repo are signed, but not the latest one.',
        explanation: 'At best, this means a sloppy release. But it could also mean a compromised release.'
      }
    end

    if unreleased > 10
      response << {
        severity: :yellow,
        message: "There are #{unreleased} commits since the last release.",
        explanation: 'Sometimes maintainers forget to make a release. Maybe you should remind them?'
      }
    end

    if new_issues > 5
      response << {
        severity: :yellow,
        message: "There have been #{new_issues} issues since the last tagged release.",
        explanation: "Many issues on a release might indicate that there's a problem with it."
      }
    end

    response
  end

  def self.cleanup
    # run just after evaluating this plugin
  end
end
