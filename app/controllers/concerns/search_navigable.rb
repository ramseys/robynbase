# Sequential navigation through a set of search results from a resource's show page.
#
# The index/quick-query actions publish a canonical URL describing the search they
# just ran (`@search_back`), which the row partials hang off every link to a show
# page. The show action replays that URL - the same collection-building code, the
# same sort, the same primary key tiebreaker - to recover the full ordered id list,
# and derives Prev/Next from the current record's position in it.
#
# Nothing is cached or stashed in the session: the search's identity is derived
# entirely from the parsed URL, which is what keeps replay deterministic (and would
# make a cache key trivial to derive later). See
# docs/plans/sequential-search-result-navigation.md.
module SearchNavigable
  extend ActiveSupport::Concern

  # Paths for the shared search_nav partial. Any of the three may be nil, which
  # simply suppresses that one button.
  SearchNav = Struct.new(:back_path, :prev_path, :next_path, keyword_init: true)

  # Quick queries take the same two params on every resource
  SEARCH_BACK_QUICK_QUERY_PARAMS = [:query_id, :query_attribute].freeze

  private

  # Canonical URL describing the search just rendered, for the row partials to hang
  # off their links to show pages.
  #
  # Built here rather than read from request.fullpath in the view because the row
  # partials are also rendered from the infinite_scroll endpoint, whose path is not
  # the index page the user should land back on.
  #
  # Call this *after* apply_sorting_and_pagination so the sort it captures is the
  # resolved one (cookie or default already applied) and replay never has to consult
  # cookies.
  def build_search_back_url(path, param_keys)
    # The sort belongs to the whitelist rather than being appended after it: it is
    # as much a part of the search being described as the search terms are.
    keys = param_keys + [:sort, :direction]

    # Slice before permitting. permit's contract is "name every key you accept and
    # I'll warn about the rest", but a listing request legitimately carries page and
    # query_type as well, which this URL deliberately leaves out - so permit logs
    # them as unpermitted on every single index and infinite_scroll request. Slicing
    # first means it only ever sees the keys we actually want.
    query = params.slice(*search_back_key_names(keys)).permit(*keys).to_h.compact_blank

    query.empty? ? path : "#{path}?#{query.to_query}"
  end

  # permit accepts nested shapes such as { release_type: [] }; slice takes plain
  # names only, so reduce the whitelist to its top-level keys.
  def search_back_key_names(keys)
    keys.flat_map { |key| key.is_a?(Hash) ? key.keys : key }
  end

  # The same canonical URL for rows served by the infinite_scroll endpoint, whose
  # own path is not somewhere the user can be sent back to. Which listing produced
  # those rows is recoverable from the params the infinite-scroll controller echoes
  # back, so this needs nothing extra from the caller.
  def build_infinite_scroll_search_back_url(index_path, quick_query_path)
    if params[:query_type] == 'quick_query'
      build_search_back_url(quick_query_path, SEARCH_BACK_QUICK_QUERY_PARAMS)
    else
      build_search_back_url(index_path, self.class::SEARCH_BACK_INDEX_PARAMS)
    end
  end

  # Parses the incoming search_back param into { action:, params:, path: }, or nil
  # if it is absent or untrustworthy.
  #
  # Validated in two stages before it is used for anything: anything carrying a URL
  # scheme or host is rejected outright, then the path must resolve to an action on
  # *this* controller. (It is never handed to redirect_to - only used to build
  # outbound link hrefs - but a cross-resource path would replay the wrong search.)
  def parse_search_back
    parsed = nil
    raw = params[:search_back]
    uri = raw.present? ? safe_parse_uri(raw) : nil

    if uri && uri.scheme.blank? && uri.host.blank? && uri.path.present?
      route = recognize_search_back_path(uri.path)

      if route && route[:controller] == controller_path
        parsed = {
          action: route[:action],
          params: Rack::Utils.parse_nested_query(uri.query).with_indifferent_access,
          path: raw
        }
      end
    end

    parsed
  end

  # The search field a listing was searching on. "all" - and a missing value, which
  # only a hand-edited search_back produces - both mean "across every field".
  def search_kind(source_params)
    kind = source_params[:search_type]

    kind.present? && kind != "all" ? kind.to_sym : nil
  end

  # Replays a quick query, but only when the id names one the resource actually
  # offers. An unknown id (only a hand-edited search_back produces one) would reach
  # the model's quick_query, come back nil and raise, taking a perfectly good show
  # page down with it.
  def replayable_quick_query(model, source_params)
    id = source_params[:query_id]

    model.quick_query(id, source_params[:query_attribute]) if model.get_quick_queries.any? { |query| query.id.to_s == id }
  end

  # Prev/Next/Back paths for the record being shown, or nil when there is no usable
  # search context. collection_builders maps a replayable action name to a lambda
  # taking the replayed params and returning the unsorted collection (or nil, when
  # those params don't describe a search that resource can run).
  def build_search_nav(id_value, collection_builders:, default_sort_params: nil)
    search = parse_search_back
    builder = search && collection_builders[search[:action]]
    nav = nil

    if builder
      collection = builder.call(search[:params])

      ids = collection.nil? ? [] : ordered_search_ids(
        collection,
        search[:params],
        default_sort_params: default_sort_params
      )

      # nil when the record no longer matches the search (data changed since it ran),
      # or when there was no replayable search at all; Prev/Next drop out but Back to
      # Search still works
      position = ids.index(id_value.to_i)

      nav = SearchNav.new(
        back_path: search[:path],
        prev_path: position.present? && position > 0 ? search_result_path(ids[position - 1], search[:path]) : nil,
        next_path: position.present? && position < ids.size - 1 ? search_result_path(ids[position + 1], search[:path]) : nil
      )
    end

    nav
  end

  # The full ordered id list for a replayed search. Both the sort resolution
  # (Paginated#resolve_sort_params) and the ordering itself (Paginated#apply_ordering)
  # are the listing's own, so positions line up exactly with what the user saw - even
  # for a hand-edited search_back that names only half of the sort pair.
  def ordered_search_ids(collection, source_params, default_sort_params:)
    # A DISTINCT relation cannot be replayed: MySQL rejects an ORDER BY on columns
    # outside a DISTINCT select list, and only the key is selected here. Silently
    # dropping the DISTINCT would rewrite the caller's query behind its back, so a
    # collection builder has to hand over a relation that is already one row per
    # record - express the filter as EXISTS/NOT EXISTS or GROUP BY instead.
    if collection.distinct_value
      raise ArgumentError, "#{collection.model.name} search collection is DISTINCT and cannot be replayed for search navigation; " \
                           "rewrite the query to return one row per record (EXISTS / NOT EXISTS or GROUP BY) instead of relying on DISTINCT"
    end

    sorted = apply_ordering(collection, **resolve_sort_params(source_params, default_sort_params))
    model = sorted.model

    # The one and only database read in this concern - keep it that way. Wrapping
    # just this expression in Rails.cache.fetch is the entire change if the replay
    # cost ever needs caching (see the plan's "forward-compatible seam").
    sorted.pluck("#{model.table_name}.#{model.primary_key}")
  end

  # A sibling result's show page, carrying the same search context forward
  def search_result_path(id, search_back)
    url_for(only_path: true, controller: controller_path, action: "show", id: id, search_back: search_back)
  end

  def safe_parse_uri(raw)
    URI.parse(raw)
  rescue URI::InvalidURIError
    nil
  end

  def recognize_search_back_path(path)
    Rails.application.routes.recognize_path(path, method: :get)
  rescue ActionController::RoutingError
    nil
  end
end
