# frozen_string_literal: true

# Pagy initializer file (9.3.5)
# Customize only what you really need but notice that the core Pagy works also without any of the following lines.
# Should you just cherry pick part of this file, please maintain the require-order and the timeframe compatibility

# Pagy DEFAULT Variables
# See https://ddnexus.github.io/pagy/docs/api/pagy#variables
# All the Pagy::DEFAULT are set for all the Pagy instances but can be overridden per instance by just passing them to
# Pagy.new|Pagy::Countless.new|Pagy::Calendar::*.new or any of the #pagy* controller methods

# Instance variables
# See https://ddnexus.github.io/pagy/docs/api/pagy#instance-variables
Pagy::DEFAULT[:size]       = 7                                          # Nav bar links
# Pagy::DEFAULT[:page]       = 1                                          # Initial page
# Pagy::DEFAULT[:count]      = nil                                        # Total items, will be retrieved by :size
Pagy::DEFAULT[:items]      = 20                                         # Items per page (default for main indexes)
Pagy::DEFAULT[:limit]      = 20                                         # SQL LIMIT (should match items)
# Pagy::DEFAULT[:outset]     = 0                                          # Initial offset
# Pagy::DEFAULT[:page_param] = :page                                      # Page parameter name
# Pagy::DEFAULT[:params]     = {}                                         # Params for link(:href) generation
# Pagy::DEFAULT[:fragment]   = '#fragment'                                # Url fragment
# Pagy::DEFAULT[:link_extra] = 'data-remote="true"'                       # Link extra attributes
# Pagy::DEFAULT[:i18n_key]   = 'pagy.item_name'                           # I18n key
# Pagy::DEFAULT[:cycle]      = true                                       # Cycles direct to the first/last page

# Extras
# See https://ddnexus.github.io/pagy/categories/extra

# Backend Extras

# Array extra: Paginate arrays efficiently, avoiding expensive array-wrapping and without overriding
# See https://ddnexus.github.io/pagy/docs/extras/array
# require 'pagy/extras/array'

# Calendar extra: Add pagination filtering by calendar time unit (year, quarter, month, week, day)
# See https://ddnexus.github.io/pagy/docs/extras/calendar
# require 'pagy/extras/calendar'
# Default for each unit
# Pagy::Calendar::UNITS.each { |unit| Pagy::DEFAULT[:"#{unit}_format"] = '%Y-%m-%d' }

# Countless extra: Paginate without any count, saving one query per rendering
# See https://ddnexus.github.io/pagy/docs/extras/countless
# require 'pagy/extras/countless'
# Pagy::DEFAULT[:countless_minimal] = false                               # Set to true for manual incremental links styling

# Elasticsearch Rails extra: Paginate `ElasticsearchRails::Results` objects
# See https://ddnexus.github.io/pagy/docs/extras/elasticsearch_rails
# Default :elasticsearch_rails_pagy_search method: change only if you use also other different searchkick gems
# require 'pagy/extras/elasticsearch_rails'
# Pagy::DEFAULT[:elasticsearch_rails_pagy_search] = :pagy_search

# Headers extra: http response headers (and other helpers) useful for API pagination
# See http://ddnexus.github.io/pagy/extras/headers
# require 'pagy/extras/headers'
# Pagy::DEFAULT[:headers] = { page: 'Current-Page',
#                            items: 'Page-Items',
#                            count: 'Total-Count',
#                            pages: 'Total-Pages' }

# Support extra: Extra support for features like: incremental, infinite, auto-scroll pagination
# See https://ddnexus.github.io/pagy/docs/extras/support
# require 'pagy/extras/support'

# Items extra: Allow the client to request a custom number of items per page with an optional selector UI
# See https://ddnexus.github.io/pagy/docs/extras/items
# require 'pagy/extras/items'
# set to false only if you want to make :enable_items_extra an opt-in variable
# Pagy::DEFAULT[:enable_items_extra] = true                               # Extra enabled by default
# Pagy::DEFAULT[:max_items]          = 100                                # Max items possible per page
# Pagy::DEFAULT[:items_param]        = :items                             # Items parameter name
# Pagy::DEFAULT[:items_extra]        = true                               # Extra enabled by default

# Meilisearch extra: Paginate `Meilisearch` result objects
# See https://ddnexus.github.io/pagy/docs/extras/meilisearch
# require 'pagy/extras/meilisearch'
# Pagy::DEFAULT[:meilisearch_pagy_search] = :pagy_search

# Metadata extra: Provides the pagination metadata to Javascript frameworks like Vue.js, react.js, etc.
# See https://ddnexus.github.io/pagy/docs/extras/metadata
# require 'pagy/extras/metadata'
# For performance reasons, you should explicitly set ONLY the metadata you use in the frontend
# Pagy::DEFAULT[:metadata] = %i[scaffold_url page prev next last]

# Searchkick extra: Paginate `Searchkick::Results` objects
# See https://ddnexus.github.io/pagy/docs/extras/searchkick
# Default :searchkick_pagy_search method: change only if you use also other different searchkick gems
# require 'pagy/extras/searchkick'
# Pagy::DEFAULT[:searchkick_pagy_search] = :pagy_search

# Frontend Extras

# Bootstrap extra: Add nav, nav_js and combo_nav_js helpers and templates for Bootstrap pagination
# See https://ddnexus.github.io/pagy/docs/extras/bootstrap
require 'pagy/extras/bootstrap'

# Bulma extra: Add nav, nav_js and combo_nav_js helpers and templates for Bulma pagination
# See https://ddnexus.github.io/pagy/docs/extras/bulma
# require 'pagy/extras/bulma'

# Foundation extra: Add nav, nav_js and combo_nav_js helpers and templates for Foundation pagination
# See https://ddnexus.github.io/pagy/docs/extras/foundation
# require 'pagy/extras/foundation'

# Materialize extra: Add nav, nav_js and combo_nav_js helpers and templates for Materialize pagination
# See https://ddnexus.github.io/pagy/docs/extras/materialize
# require 'pagy/extras/materialize'

# Navs extra: Add nav_js and combo_nav_js helpers without templates
# See https://ddnexus.github.io/pagy/docs/extras/navs
# require 'pagy/extras/navs'

# Semantic extra: Add nav, nav_js and combo_nav_js helpers and templates for Semantic UI pagination
# See https://ddnexus.github.io/pagy/docs/extras/semantic
# require 'pagy/extras/semantic'

# UIkit extra: Add nav, nav_js and combo_nav_js helpers and templates for UIkit pagination
# See https://ddnexus.github.io/pagy/docs/extras/uikit
# require 'pagy/extras/uikit'

# Feature Extras

# Gearbox extra: Automatically change the number of items per page depending on the page number
# See https://ddnexus.github.io/pagy/docs/extras/gearbox
# require 'pagy/extras/gearbox'
# set to false only if you want to make :enable_gearbox_extra an opt-in variable
# Pagy::DEFAULT[:enable_gearbox_extra] = false                            # Extra disabled by default
# Pagy::DEFAULT[:gearbox_extra]        = true                             # Extra enabled by default
# Pagy::DEFAULT[:gearbox_items]        = [15, 20, 25, 30]                 # Custom gearbox items

# Limit extra: Paginate with bounded pages
# See https://ddnexus.github.io/pagy/docs/extras/limit
# require 'pagy/extras/limit'
# Pagy::DEFAULT[:limit_extra] = true                                      # Extra enabled by default
# Pagy::DEFAULT[:limit_max]   = 100                                       # Max page limit

# Overflow extra: Allow for easy handling of overflowing pages
# See https://ddnexus.github.io/pagy/docs/extras/overflow
# require 'pagy/extras/overflow'
# Pagy::DEFAULT[:overflow] = :empty_page                                  # :last_page, :empty_page, :exception

# Standalone extra: Use pagy in non Rack environment/gem
# See https://ddnexus.github.io/pagy/docs/extras/standalone
# require 'pagy/extras/standalone'
# Pagy::DEFAULT[:url] = 'http://www.example.com/subdir'                   # Base url

# Trim extra: Remove the page=1 param from links
# See https://ddnexus.github.io/pagy/docs/extras/trim
# require 'pagy/extras/trim'
# set to false only if you want to make :enable_trim_extra an opt-in variable
# Pagy::DEFAULT[:enable_trim_extra] = true                                # Extra enabled by default
# Pagy::DEFAULT[:trim_extra]        = true                                # Extra enabled by default

# Rails

# I18n
# See https://ddnexus.github.io/pagy/docs/api/frontend#i18n

# When you are done setting your own default freeze them, so they are set only once during the app initialization
# This also improves performance of new Pagy instances
Pagy::DEFAULT.freeze