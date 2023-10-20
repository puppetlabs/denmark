# frozen_string_literal: true

# environments plugin
class Denmark::Plugins::Issues
  def self.description
    # This is a Ruby squiggle heredoc; just a multi-line string with indentation removed
    <<~DESCRIPTION
      This smell test infers trends about the responsiveness of a module's maintainer(s)
      based on patterns in its repository issues.
    DESCRIPTION
  end

  def self.setup
    # run just before evaluating this plugin
  end

  def self.run(_mod, repo)
    # return an array of hashes representing any smells discovered
    response = []
    today = Date.today
    unanswered = repo.issues.percent_of { |i| i.comments.zero? }
    ancient    = repo.issues.percent_of { |i| (today - i.created_at.to_date).to_i > 1095 } # more than 3 years old

    if unanswered > 25
      response << {
        severity: :orange,
        message: "#{unanswered}% of the issues in this module's repository have no responses.",
        explanation: 'Sometimes when issues are not responded to, it means that the project is no longer being maintained.
        You might consider contacting the maintainer to determine the status of the project.'
      }
    end

    if ancient > 50
      response << {
        severity: :yellow,
        message: "#{ancient}% of the issues in this module's repository are more than 3 years old.",
        explanation: 'Many very old issues may indicate that the maintainer is not responding to community feedback.'
      }
    end

    response
  end

  def self.cleanup
    # run just after evaluating this plugin
  end
end
