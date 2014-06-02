AutoHtml.add_filter(:opengraph_link).with({}) do |text, options|
  require 'url_scraper'
  require 'uri'
  require 'rinku'
  require 'rexml/document'
  
  def remote_file_exists?(url)
    url = URI.parse(url)
    return false unless url.host.present?
    return false unless url.respond_to?(:request_uri)
    Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https') do |http|
      begin
        return http.head(url.request_uri)['Content-Type'] && http.head(url.request_uri)['Content-Type'].start_with?('image')
      rescue Errno::ECONNRESET => e
        false
      end
    end
  end

  option_short_link_name = options.delete(:short_link_name)
  attributes = Array(options).reject { |k,v| v.nil? }.map { |k, v| %{#{k}="#{REXML::Text::normalize(v)}"} }.join(' ')
  Rinku.auto_link(text, :all, attributes) do |url|
    html = ''
    if option_short_link_name
      uri = URI.parse(URI.encode(url.strip))
      uri.query = nil
      url = uri.to_s
      #hax for urlscaper URI::BadURIError: both URI are relative
      url.gsub!('www.','http://') if url.match(/^www./).present?
      og = UrlScraper.fetch(url)
      if og
        image = og.image.detect{|i| remote_file_exists?(i)}
        html += "<div class='og'>"
        html += "<img src=#{image} >" if image.present?
        html += "<p class='og_title'>#{og.title}</p>" 
        html += "<p class='og_url'>#{og.site_name}</p>"
        html += "<p class='og_description'>#{og.description}</p></div>"
        html
      else 
        uri.to_s
      end
    else
      #hax for urlscaper URI::BadURIError: both URI are relative
      url.gsub!('www.','http://') if url.match(/^www./).present?
      og = UrlScraper.fetch(url)
      if og
        image = og.image.detect{|i| remote_file_exists?(i)}
        html += "<div class='og'>"
        html += "<img src=#{image} >" if image.present?
        html += "<p class='og_title'>#{og.title}</p>" 
        html += "<p class='og_url'>#{og.site_name}</p>"
        html += "<p class='og_description'>#{og.description}</p></div>"
        html 
      else
    	url
      end
    end
  end
end 
