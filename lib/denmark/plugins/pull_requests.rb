# frozen_string_literal: true

# environments plugin
class Denmark::Plugins::PullRequests
  def self.description
    # This is a Ruby squiggle heredoc; just a multi-line string with indentation removed
    <<~DESCRIPTION
      This smell test infers trends about the responsiveness of a module's maintainer(s)
      based on patterns in its repository pull requests.
    DESCRIPTION
  end

  def self.setup
    # run just before evaluating this plugin
  end

  def self.run(_mod, repo)
    # return an array of hashes representing any smells discovered
    response = []

    today = Date.today
    unanswered = repo.pull_requests.percent_of { |i| i.comments.zero? }
    ancient    = # more than 3 years old
      repo.pull_requests.percent_of do |i|
        (today - i.created_at.to_date).to_i > 1095
      end
    if unanswered > 10
      response << {
        severity: :orange,
        message: "#{unanswered}% of the pull requests in this module's repository have not been reviewed.",
        explanation: 'Sometimes when pull requests are not reviewed, it means that the project is no longer being maintained.
        You might consider contacting the maintainer to determine the status of the project.'
      }
    end

    if ancient > 50
      response << {
        severity: :yellow,
        message: "#{ancient}% of the pull requests in this module's repository are more than 3 years old.",
        explanation: 'Many very old pull requests may indicate that the maintainer is not merging community contributions.'
      }
    end

    response
  end

  def self.cleanup
    # run just after evaluating this plugin
  end
end
