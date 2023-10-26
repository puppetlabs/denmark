# frozen_string_literal: true

require 'date'
require 'denmark/plugins/issues'

describe Denmark::Plugins::Issues do
  describe '.description' do
    it 'returns a description string' do
      description = described_class.description
      expect(description).to be_a(String)
      expect(description).not_to be_empty
    end
  end

  describe '.run' do
    let(:module_repo) { double('Repository') }

    it 'returns an array of hashes representing smells' do
      allow(module_repo).to receive_message_chain(:issues, :percent_of).and_return(30)
      allow(module_repo).to receive_message_chain(:issues, :percent_of).and_return(40)

      smells = described_class.run('module_name', module_repo)

      expect(smells).to be_an(Array)
      expect(smells.first).to include(:severity, :message, :explanation)
    end

    it 'generates an orange smell for a high percentage of unanswered issues' do
      allow(module_repo).to receive_message_chain(:issues, :percent_of).and_return(30)

      smells = described_class.run('module_name', module_repo)

      expect(smells.first).to include(severity: :orange)
    end

    it 'generates a yellow smell for a high percentage of ancient issues' do
      allow(module_repo).to receive_message_chain(:issues, :percent_of).and_return(55)

      smells = described_class.run('module_name', module_repo)

      expect(smells[1]).to include(severity: :yellow)
    end
  end
end
