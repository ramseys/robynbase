require 'csv'
require 'active_record'

require_relative '../app/models/application_record.rb'
require_relative '../app/models/venue.rb'

# CSV Venue Location Import Utilities
module CsvVenueImportLocation

  # Write the given venue info to console
  def self.print_venue(v)
    puts("[#{v[:venue_name]}] / City: #{v[:city]} / SubCity: #{v[:subcity]} / State: #{v[:state]} / Country: #{v[:country]}")
  end

  # Returns the given venue in CSV format, using a pipe (|) separator)
  def self.venue_to_csv(v)
    "#{v[:id]}|#{v[:SubCotu]}|#{v[:street_address1]}|#{v[:street_address2]}|#{v[:latitude]}|#{v[:longitude]}"
  end

  # compares the given column and csv values
  def self.values_eq(col_value, csv_value)
    (col_value.blank? and csv_value.blank?) or
    (col_value == csv_value)
  end

  # determines if the venue info changed values in an existing venue
  def self.venue_changed(venue, venue_info)
    ["SubCity", "street_address1", "street_address2", "latitude", "longitude"].any? {|col|
      not self.values_eq(venue[col], venue_info[col.downcase.to_sym])
    }
  end

  # populate the given venue with updated venue info
  def self.populate_venue(venue, venue_info)    
    venue.SubCity = venue_info[:subcity]
    venue.street_address1 = venue_info[:street_address1]
    venue.street_address2 = venue_info[:street_address2]
    venue.latitude = venue_info[:latitude]
    venue.longitude = venue_info[:longitude]

    venue
  end

  # Returns the given list of venues in CSV format. The CSV:
  #   - Uses pipe (|) as the separator
  #   - Includes column names on the first line
  def self.venues_to_csv(venues)
    a = "VENUEID|SubCity|street_address1|street_address2|latitude|longitude\n"
    a + venues.map {|v| "#{venue_to_csv(v)}"}.join("\n")
  end

  # update the given list of venues in the database
  def self.update(venues)

    venues.each do |venue_info|

      venue = Venue.find(venue_info[:id])
      self.populate_venue(venue, venue_info)

      venue.save

    end

  end


  # Analyzes the given CSV table, to prepare the venues for import. Extracts venues that:
  #
  # 1. Need to be updated
  # 2. Don't need to be updated
  # 2. Don't have enough location info to be updated
  # 3. Are missing (ie, the venue id lookup failed)
  #
  # Returns a tuple with one array for each category
  def self.analyze_venues(import_table)

    # the categories of venues extracted from the venue table
    missing_venues = []
    updated_venues = []
    unchanged_venues = []
    incomplete_venues = []

    # mismatched_venues = []

    # loop through each row of the table
    import_table.each { |row|

      # put together data on the venue
      venue_info = {
          :id               => row['VENUEID'].nil? ? nil         : row['VENUEID'],
          :subcity          => row['SubCity'].nil? ? nil         : row['SubCity'].strip,
          :street_address1  => row['street_address1'].nil? ? nil : row['street_address1'].strip,
          :street_address2  => row['street_address2'].nil? ? nil : row['street_address2'].strip,
          :latitude         => row['latitude'].nil? ?  nil       : row['latitude'],
          :longitude        => row['longitude'].nil? ? nil       : row['longitude']
      }

      if venue_info[:id].nil? or venue_info[:longitude].nil? or venue_info[:latitude].nil?
        incomplete_venues.push(venue_info);

      else

        # look up the venue of the current gig in the database
        venue = Venue.find(venue_info[:id])
        
        # if the venue exists, check if anything changed
        if venue.present?

          if self.venue_changed(venue, venue_info)
            updated_venues.push(venue_info) 
          else
            unchanged_venues.push(venue_info)
          end

        else  
          missing_venues.push(venue_info);
        end

      end

    }

    [missing_venues, updated_venues, unchanged_venues, incomplete_venues]

  end

  # create csvs for each category of venue data
  def self.dump_venue_csv(venue_analysis, output_csv_directory)

    missing_venues_csv = "#{output_csv_directory}/venues_missing.csv"
    updated_venues_csv = "#{output_csv_directory}/venues_updated.csv"
    unchanged_venues_csv = "#{output_csv_directory}/venues_unchanged.csv"
    incomplete_venues_csv = "#{output_csv_directory}/venues_incomplete.csv"

    # missing_venues, mismatched_venues, data_issues = venue_analysis
    missing_venues, updated_venues, unchanged_venues, data_issues = venue_analysis

    File.write(updated_venues_csv, venues_to_csv(updated_venues))
    puts("Updated Venues: #{updated_venues_csv}")

    File.write(missing_venues_csv, venues_to_csv(missing_venues))
    puts("Missing Venues: #{missing_venues_csv}")

    File.write(incomplete_venues_csv, venues_to_csv(data_issues))
    puts("Incomplete Venues: #{incomplete_venues_csv}")

    File.write(unchanged_venues_csv, venues_to_csv(unchanged_venues))
    puts("Unchanged Venues: #{unchanged_venues_csv}")

  end


  # perform the import
  def self.import_venues(import_table, preview_only = false, output_csv_directory = nil, no_updates = false, no_creates = false)

    venue_analysis = self.analyze_venues(import_table)

    if output_csv_directory.present?
      self.dump_venue_csv(venue_analysis, output_csv_directory)
    end

    missing_venues, updated_venues, mismatched_venues, data_issues = venue_analysis

    unless preview_only

      if updated_venues.present?
        puts 'Updating changed venues'
        self.update(updated_venues)
      end

    end
    
  end

end