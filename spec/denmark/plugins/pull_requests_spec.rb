# frozen_string_literal: true

require 'date'
require 'denmark/plugins/pull_requests'

describe Denmark::Plugins::PullRequests do
  let(:mod) { double('Module') }
  let(:repo) { double('Repository') }
  let(:today) { Date.new(2023, 1, 1) }
  let(:pull_requests) { [] }

  before(:each) do
    allow(mod).to receive(:releases).and_return([])
    allow(repo).to receive(:pull_requests).and_return(pull_requests)
  end

  describe '.description' do
    it 'returns a description string' do
      description = described_class.description
      expect(description).to be_a(String)
      expect(description).not_to be_empty
    end
  end

  describe '.run' do
    it 'returns an array of hashes representing smells' do
      smells = described_class.run(mod, repo)

      expect(smells).to be_an(Array)
    end

    it 'generates an orange smell for a high percentage of unanswered pull requests' do
      pull_requests = [
        double('PullRequest', comments: 0, created_at: today - 10),
        double('PullRequest', comments: 0, created_at: today - 15),
      ]

      allow(repo).to receive(:pull_requests).and_return(pull_requests)

      smells = described_class.run(mod, repo)

      expect(smells.first).to include(severity: :orange)
    end

    it 'generates a yellow smell for a high percentage of ancient pull requests' do
      pull_requests = [
        double('PullRequest', comments: 1, created_at: today - 1096),
        double('PullRequest', comments: 0, created_at: today - 1100),
      ]

      allow(repo).to receive(:pull_requests).and_return(pull_requests)

      smells = described_class.run(mod, repo)

      expect(smells[1]).to include(severity: :yellow)
    end
  end
end
