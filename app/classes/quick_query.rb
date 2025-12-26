class QuickQuery 

  attr_reader :area, :id, :secondary_queries

  def initialize (area, id, secondary_queries = nil)
    @area = area
    @id = id
    @secondary_queries = secondary_queries
  end

  def render
    
  end

  def route(query_attribute)
    route = "/#{@area}/quick_query?query_id=#{@id}"

    if (query_attribute.present?)
      route += "&query_attribute=#{query_attribute}"
    end

    route

  end

  def label(query_attribute)

    resource = @id.to_s

    if (query_attribute.present?)
      resource = resource + "_#{query_attribute}" 
    end

    I18n.t resource, scope: [:quick_query, @area]

  end
  
  def full_label(query_attribute)

    full_query_attribute = "#{query_attribute}_full" if query_attribute.present?
    
    label(full_query_attribute)

  end



end