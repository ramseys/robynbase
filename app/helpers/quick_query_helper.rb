module QuickQueryHelper

  def render_quick_query(qq)

    q = render_link(qq)

    if qq.secondary_queries.present?

      qq.secondary_queries.each do |secondary| 
        q = q + "<small>#{render_link(qq, secondary)}</small>"
      end

    end

    q.html_safe

  end

  def get_all_quick_queries(type)
    if type.get_quick_queries.present?
      type.get_quick_queries.collect {|qq| render_quick_query(qq)}
    end
  end

  # get 5 random queries, across the given object types
  def get_random_quick_queries(types)
    allTypes = types.collect {|type| type.get_quick_queries}.flatten
    prng = Random.new
    random_qq = allTypes.sort {|item1, item2| prng.rand(-1 .. 1)  }.slice(0, 5)
    random_qq.collect {|qq| render_quick_query(qq)}
  end

  def render_link(qq, secondary = nil)
    "<a href='#{qq.route(secondary)}' data-turbo-frame='table_frame'>#{qq.label(secondary)}</a>"
  end

end