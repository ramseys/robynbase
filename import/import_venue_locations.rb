require_relative '../config/boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'csv'
require 'active_record'
require "active_storage"

require_relative '../app/models/application_record.rb'
require_relative '../app/classes/quick_query.rb'
require_relative '../app/models/venue.rb'

require_relative '../import/CsvVenueImportLocation'

require 'optparse'
require 'yaml'

# load up db info for the current environment
config = YAML.load(File.read('../config/database.yml'))
env_db_config = config[ENV['RAILS_ENV']]

# establish connection to database
ActiveRecord::Base.establish_connection(
    adapter: 'mysql2',
    database: env_db_config['database'],
    host: env_db_config['host'],
    port: env_db_config['port'],
    username: env_db_config['username'],
    password: env_db_config['password']
)


custom_converter = lambda { |value, field_info|

  if value == "NULL"
    nil
  else
    case field_info.header
      # when 'GigDate', 'StartTime', 'ModifyDate'
      # puts "date #{field_info.header}: #{value}"
      # DateTime.strptime(value, '%m/%d/%y %H:%M')
      # puts(value)
      # DateTime.strptime(value, '%Y-%m-%d %H:%M:%S')
      when 'Circa', 'TapeExists', 'Favorite'
        value != "0"
      else
        value
    end
  end

}


def get_col_value(row, col)
  row[col].nil? ? '' : row[col].strip
end


import_csv_file = ARGV[0]

# pull in the csv file we're importing, and convert it into a CSV table
import_table = CSV.parse(File.read(import_csv_file), headers: true, converters: [custom_converter, :numeric, :date_time])


options = {
    :preview => false,
    :csv => nil
}

OptionParser.new do |opts|
  opts.banner = "Usage: import_csv.rb CSV_FILE [options]"

  opts.on("-cCSVDIR", "--csv", "Write CSV action to the given directory") do |c|
    options[:csv] = c
  end

  opts.on("-p", "--preview", "Show preview of import only. Must be paired with --csv option") do |c|
    options[:preview] = c
  end

end.parse!

CsvVenueImportLocation.import_venues(import_table, options[:preview], options[:csv], options[:noupdate], options[:noadd])
