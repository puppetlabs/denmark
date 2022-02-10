# frozen_string_literal: true

class Denmark::Repository
  def initialize(url)
    # This tool only makes sense for public repos, so don't bother to be too smart.
    case url
    when /github\.com/
      require 'octokit'
      @flavor = :github
      @client = Octokit::Client.new(:access_token => Denmark.config(:github, :token))
      @repo   = Octokit::Repository.from_url(url).slug

    when /gitlab\.com/
      require 'gitlab'
      @flavor = :gitlab
      @client = Gitlab.client(
                  endpoint:      'https://gitlab.com/api/v4',
                  private_token: Denmark.config(:gitlab, :token),
                )
      @repo   = URI.parse(url).path[1..-1]

    else
      raise "Unsupported git source: '#{url}'"
    end
  end

  def client
    @client
  end

  def pull_requests
    case @flavor
    when :github
      @client.issues(@repo).select {|i| i[:pull_request] }
    when :gitlab
      @client.merge_requests(@repo)
    else
      Array.new
    end
  end

  def merge_requests
    pull_requests
  end

  def issues
    case @flavor
    when :github
      @client.issues(@repo).reject {|i| i[:pull_request] }
    when :gitlab
      @client.issues(@repo)
    else
      Array.new
    end
  end

  def issues_since_tag(tag = nil)
    tag ||= tags[0]
    case @flavor
    when :github
      issues_since(commit_date(tag.commit.sha))
    when :gitlab
      issues_since(tag.commit.created_at)
    end
  end

  def issues_since(date)
    case @flavor
    when :github
      @client.issues(@repo, {:state => 'open', :since=> date}).reject {|i| i[:pull_request] }
    when :gitlab
      @client.issues(@repo, updated_after: date)
    else
      Array.new
    end
  end

  def tags
    case @flavor
    when :github, :gitlab
      @client.tags(@repo)
    else
      Array.new
    end
  end

  def file_content(path)
    case @flavor
    when :github
      Base64.decode64(client.contents(@repo, :path => path).content) rescue nil
    when :gitlab
      client.file_contents(@repo, path)
    else
      ''
    end
  end

  def commit(sha)
    case @flavor
    when :github, :gitlab
      @client.commit(@repo, sha)
    else
      Array.new
    end
  end

  def commits
    case @flavor
    when :github, :gitlab
      @client.commits(@repo)
    else
      Array.new
    end
  end

  def commit_date(sha)
    case @flavor
    when :github
      @client.commit(@repo, sha).commit.committer.date.to_date
    when :gitlab
      @client.commit(@repo, sha).commit.created_at.to_date
    else
      Array.new
    end
  end

  def commits_since_tag(tag = nil)
    tag ||= tags[0]

    case @flavor
    when :github
      @client.commits_since(@repo, commit_date(tag.commit.sha))
    when :gitlab
      @client.commits(@repo, since: tag.commit.created_at)
    else
      Array.new
    end
  end

  def commits_to_file(path)
    case @flavor
    when :github, :gitlab
      @client.commits(@repo, path: path)
    else
      Array.new
    end
  end

end
