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

  def self.run(mod, repo)
    # return an array of hashes representing any smells discovered
    response = Array.new

    unreleased = repo.commits_since_tag.size
    new_issues = repo.issues_since_tag.size

    if unreleased > 10
      response << {
        severity: :yellow,
        message: "There are #{unreleased} commits since the last release.",
        explanation: "Sometimes maintainers forget to make a release. Maybe you should remind them?",
      }
    end

    if new_issues > 5
      response << {
        severity: :yellow,
        message: "There have been #{new_issues} issues since the last tagged release.",
        explanation: "Many issues on a release might indicate that there's a problem with it.",
      }
    end

    response
  end

  def self.cleanup
    # run just after evaluating this plugin
  end
end
