require "googleajax"

class Google
  def self.search(title, site)
    GoogleAjax.referrer = "24.14.247.168" # fix
    if site.nil?
      results = GoogleAjax::Search.web("\"#{title}\"")
    else
      results = GoogleAjax::Search.web("site:#{site} \"#{title}\"")
    end
    count = results[:cursor][:result_count].to_s.delete(",").to_i
    p "#{title} #{site} count: #{count}"
    return count
  end
end
