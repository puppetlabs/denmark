# frozen_string_literal: true

require 'date'
require 'denmark/plugins/metadata'
require 'semantic_puppet'

describe Denmark::Plugins::Metadata do
  let(:mod) { double('Module', releases: releases) }
  let(:repo) { double('Repository') }
  let(:releases) { [release1, release2] }
  let(:release1) do
    double(
      'Release',
      updated_at: '2023-01-01T00:00:00Z',
      version: '1.0.0',
      changelog: 'Changelog 1',
    )
  end
  let(:release2) do
    double(
      'Release',
      updated_at: '2022-01-01T00:00:00Z',
      version: '0.9.0',
      changelog: 'Changelog 2',
    )
  end

  before(:each) do
    allow(mod).to receive(:releases).and_return(releases)
    allow(repo).to receive_messages(tags: [tag], commit_date: '2023-01-01T00:00:00Z')
    allow(repo).to receive(:file_content).with('metadata.json').and_return('{"version":"1.0.0"}')
    allow(repo).to receive(:file_content).with('CHANGELOG.md').and_return('Changelog 1')
  end

  describe '.description' do
    let(:tag) { double('Tag', name: 'v1.0.0', commit: double('Commit', sha: 'abcd1234')) }

    it 'returns a description string' do
      description = described_class.description
      expect(description).to be_a(String)
      expect(description).not_to be_empty
    end
  end

  describe '.run' do
    let(:tag) { double('Tag', name: 'v1.0.0', commit: double('Commit', sha: 'abcd1234')) }

    it 'returns an array of hashes representing smells' do
      smells = described_class.run(mod, repo)

      expect(smells).to be_an(Array)
      expect(smells.first).to include(:severity, :message, :explanation)
    end

    it 'generates a green smell for a recent release' do
      allow(mod).to receive_message_chain(:releases, :first, :updated_at).and_return((Date.today - 1).to_s)
      allow(mod).to receive_message_chain(:releases, :first, :version).and_return('1.0.0')
      allow(mod).to receive_message_chain(:releases, :first, :changelog).and_return('SampleChangeLog')
      smells = described_class.run(mod, repo)
      green_smells = smells.select { |smell| smell[:severity] == :green }

      expect(green_smells.first).to include(severity: :green)
    end

    it 'generates a red smell for version discrepancy' do
      allow(repo).to receive(:tags).and_return([tag])
      allow(mod).to receive_message_chain(:releases, :first, :updated_at).and_return((Date.today - 1).to_s)
      allow(mod).to receive_message_chain(:releases, :first, :version).and_return('2.0.0')
      allow(mod).to receive_message_chain(:releases, :first, :changelog).and_return('SampleChangeLog')

      smells = described_class.run(mod, repo)
      red_smells = smells.select { |smell| smell[:severity] == :red }

      expect(red_smells.first).to include(severity: :red)
    end

    it 'generates a yellow smell for tag and Forge date discrepancies' do
      allow(repo).to receive_messages(tags: [tag], commit_date: '2022-01-02T00:00:00Z')

      smells = described_class.run(mod, repo)
      yellow_smells = smells.select { |smell| smell[:severity] == :yellow }

      expect(yellow_smells.first).to include(severity: :yellow)
    end

    it 'generates a green smell for a release more than a year old' do
      allow(mod).to receive_message_chain(:releases, :first, :updated_at).and_return((Date.today - 370).to_s)
      allow(mod).to receive_message_chain(:releases, :first, :version).and_return('1.0.0')
      allow(mod).to receive_message_chain(:releases, :first, :changelog).and_return('SampleChangeLog')
      smells = described_class.run(mod, repo)
      green_smells = smells.select { |smell| smell[:severity] == :green }

      expect(green_smells.first).to include(severity: :green)
    end
  end
end
