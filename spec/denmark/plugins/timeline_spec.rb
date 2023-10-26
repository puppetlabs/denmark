# frozen_string_literal: true

require 'date'
require 'denmark/plugins/timeline'

describe Denmark::Plugins::Timeline do
  let(:mod) { double('Module') }
  let(:repo) { double('Repository') }

  before(:each) do
    allow(repo).to receive_messages(tags: [double('Tag', name: 'v1.0.0')], commits_since_tag: [], issues_since_tag: [], committers: [], verified: true)
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
      allow(repo).to receive_message_chain(:commits, :percent_of).and_return(20)
      smells = described_class.run(mod, repo)

      expect(smells).to be_an(Array)
      expect(smells.first).to include(:severity, :message, :explanation)
    end

    it 'generates a yellow smell for unreleased commits' do
      allow(repo).to receive_message_chain(:commits, :percent_of).and_return(20)
      allow(repo).to receive(:commits_since_tag).and_return([double('Commit')])
      smells = described_class.run(mod, repo)

      yellow_smells = smells.select { |smell| smell[:severity] == :yellow }

      expect(yellow_smells.first).to include(severity: :yellow)
    end

    it 'generates a yellow smell for a high number of new issues' do
      allow(repo).to receive_message_chain(:commits, :percent_of).and_return(20)
      allow(repo).to receive(:issues_since_tag).and_return([double('Issue'), double('Issue')])
      smells = described_class.run(mod, repo)

      yellow_smells = smells.select { |smell| smell[:severity] == :yellow }

      expect(yellow_smells.first).to include(severity: :yellow)
    end

    it 'generates a yellow smell for unsigned commits' do
      allow(repo).to receive_message_chain(:commits, :percent_of).and_return(20)
      allow(repo).to receive(:verified).and_return(false)
      smells = described_class.run(mod, repo)

      yellow_smells = smells.select { |smell| smell[:severity] == :yellow }

      expect(yellow_smells.first).to include(severity: :yellow)
    end

    it 'generates a yellow smell for unsigned tags' do
      allow(repo).to receive_message_chain(:commits, :percent_of).and_return(20)
      allow(repo).to receive(:tags).and_return([double('Tag', name: 'v1.0.0', verified: false)])
      smells = described_class.run(mod, repo)

      yellow_smells = smells.select { |smell| smell[:severity] == :yellow }

      expect(yellow_smells.first).to include(severity: :yellow)
    end

    it 'generates a yellow smell for unreleased commits more than 10' do
      allow(repo).to receive_message_chain(:commits, :percent_of).and_return(5)
      allow(repo).to receive_message_chain(:commits_since_tag, :size).and_return(20)
      smells = described_class.run(mod, repo)

      yellow_smells = smells.select { |smell| smell[:severity] == :yellow }

      expect(yellow_smells[1]).to include(severity: :yellow)
    end

    it 'generates a yellow smell for issues more than 5 since last tag' do
      allow(repo).to receive_message_chain(:commits, :percent_of).and_return(5)
      allow(repo).to receive_message_chain(:issues_since_tag, :size).and_return(20)
      smells = described_class.run(mod, repo)

      yellow_smells = smells.select { |smell| smell[:severity] == :yellow }

      expect(yellow_smells[1]).to include(severity: :yellow)
    end

    it 'generates a red smell for an unsigned latest tag' do
      allow(repo).to receive_message_chain(:commits, :percent_of).and_return(20)
      allow(repo).to receive_message_chain(:tags, :percent_of).and_return(90)
      allow(repo).to receive(:verified).and_return(false)
      smells = described_class.run(mod, repo)

      red_smells = smells.select { |smell| smell[:severity] == :red }

      expect(red_smells.first).to include(severity: :red)
    end

    it 'generates a yellow smell for a single tagger' do
      allow(repo).to receive_message_chain(:commits, :percent_of).and_return(20)
      allow(repo).to receive(:committers).and_return(['SingleTagger'])
      smells = described_class.run(mod, repo)

      yellow_smells = smells.select { |smell| smell[:severity] == :yellow }

      expect(yellow_smells.first).to include(severity: :yellow)
    end

    it 'generates a green smell for 15-85 unsigned commits' do
      allow(repo).to receive_message_chain(:commits, :percent_of).and_return(50)
      allow(repo).to receive(:tags).and_return([double('Tag', name: 'v1.0.0', verified: false)])
      smells = described_class.run(mod, repo)

      green_smells = smells.select { |smell| smell[:severity] == :green }

      expect(green_smells.first).to include(severity: :green)
    end

    it 'generates a green smell for 15-85 unsigned tags' do
      allow(repo).to receive_message_chain(:commits, :percent_of).and_return(5)
      allow(repo).to receive_message_chain(:tags, :percent_of).and_return(50)
      smells = described_class.run(mod, repo)

      green_smells = smells.select { |smell| smell[:severity] == :green }

      expect(green_smells.first).to include(severity: :green)
    end
  end
end
