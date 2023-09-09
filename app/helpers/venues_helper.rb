module VenuesHelper

    def build_address(venue)

        address = ""

        address << "#{venue.street_address1} <br/>" if venue.street_address1.present?
        address << "#{venue.street_address2} <br/>" if venue.street_address2.present?
        address << "#{venue.SubCity} <br/>" if venue.SubCity.present?
        address << "#{venue.City}, " if venue.City.present?
        address << "#{venue.State} <br/>" if venue.State.present?
        address << "#{venue.Country}" if venue.Country.present?
       
        address.html_safe

    end
end
