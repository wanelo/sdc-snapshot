require 'oj'
require 'pry-nav'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f unless /_spec\.rb$/.match(f) }

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.include ArubaDoubles

  config.before :each do
    ArubaDoubles::Double.setup
  end

  config.after :each do
    ArubaDoubles::Double.teardown
    history.clear
  end

  config.order = 'random' # run `be rspec --seed 1234` for deterministic ordering
end
