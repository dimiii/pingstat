require 'rspec'
require 'rack/test'

require_relative '../app/domain'

describe 'Math' do
  include Rack::Test::Methods

  it 'calculates metrics' do
    tstart = Time.parse('2012-12-12T06:06')
    tfinish = Time.parse('2012-12-12T06:13')

    expected = {:rtt => {:avg => 10.5, :min => 1, :max => 32, :med => 6.0, :sd => 11.86}, :loss => 0.14}
    expect(SummaryReport.new([1, 2, 4, 8, 16, 32], tstart, tfinish, 60).to_hash).to eq expected

    expected = {:rtt => {:avg => 6.2, :min => 1, :max => 16, :med => 4, :sd => 6.1}, :loss => 0.29}
    expect(SummaryReport.new([16, 8, 4, 2, 1], tstart, tfinish, 60).to_hash).to eq expected

    expected = {:rtt => {:avg => 1.0, :min => 1, :max => 1, :med => 1, :sd => 0.0}, :loss => 0.0}
    expect(SummaryReport.new([1, 1, 1, 1, 1, 1, 1], tstart, tfinish, 60).to_hash).to eq expected

    expected = {:rtt => {:avg => nil, :min => nil, :max => nil, :med => nil, :sd => nil}, :loss => 1.0}
    expect(SummaryReport.new([], tstart, tfinish, 60).to_hash).to eq expected

    expected = {:rtt => {:avg => 1.0, :min => 1, :max => 1, :med => 1.0, :sd => nil}, :loss => 0.86}
    expect(SummaryReport.new([1], tstart, tfinish, 60).to_hash).to eq expected

    expected = {:rtt => {:avg => nil, :min => nil, :max => nil, :med => nil, :sd => nil}, :loss => nil}
    expect(SummaryReport.new([], tstart, tstart + 59, 60).to_hash).to eq expected
  end


end

