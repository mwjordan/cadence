require 'rails_helper'

RSpec.describe AppRenameService do
  let(:root) { Rails.root.to_s }

  describe '#call' do
    it 'raises error for blank name' do
      expect { AppRenameService.new('').call }.to raise_error(ArgumentError, /blank/)
    end

    it 'raises error for name starting with a number' do
      expect { AppRenameService.new('123app').call }.to raise_error(ArgumentError, /start with a letter/)
    end

    it 'raises error for name with special characters' do
      expect { AppRenameService.new('my@app').call }.to raise_error(ArgumentError, /only contain/)
    end

    it 'converts names to correct formats' do
      service = AppRenameService.new('My Cool App')

      # Test private methods via send
      expect(service.send(:pascal_name)).to eq('MyCoolApp')
      expect(service.send(:snake_name)).to eq('my_cool_app')
      expect(service.send(:human_name)).to eq('My Cool App')
    end

    it 'handles hyphenated names' do
      service = AppRenameService.new('my-cool-app')

      expect(service.send(:pascal_name)).to eq('MyCoolApp')
      expect(service.send(:snake_name)).to eq('my_cool_app')
      expect(service.send(:human_name)).to eq('My Cool App')
    end

    it 'handles underscored names' do
      service = AppRenameService.new('my_cool_app')

      expect(service.send(:pascal_name)).to eq('MyCoolApp')
      expect(service.send(:snake_name)).to eq('my_cool_app')
      expect(service.send(:human_name)).to eq('My Cool App')
    end
  end
end
