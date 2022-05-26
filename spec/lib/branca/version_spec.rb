# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Branca do
  it 'must have a version number' do
    expect(Branca::VERSION).to eq('1.0.2')
  end
end
