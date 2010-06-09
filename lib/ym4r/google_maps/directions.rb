require 'open-uri'
require 'rexml/document'
require 'cgi'

module Ym4r
  module GoogleMaps
	module Directions

	  GEO_SUCCESS = 200
	  GEO_MISSING_ADDRESS = 601
	  GEO_UNKNOWN_ADDRESS = 602
	  GEO_UNAVAILABLE_ADDRESS = 603
	  GEO_BAD_KEY = 610
	  GEO_TOO_MANY_QUERIES = 620
	  GEO_SERVER_ERROR = 500

    # Travel modes
    TRAVEL_MODE_DRIVING = 'driving'
    TRAVEL_MODE_WALKING = 'walking'
    TRAVEL_MODE_BICYCLING = 'bicycling'
	  
	  #Gets directions by querying the Google Maps Geocoding service with the +request+ string. Options can be Google's TLD (com by default), travel mode (see Travel modes)
	  def self.get(origin, destination, options = {})
      tld = options[:tld] || 'com'
      params = Hash.new
      params[:origin] = origin
      params[:destination] = destination
      params[:sensor] = false
      params[:travel_mode] = options[:travel_mode]
      query = params.collect {|i| "#{i.first}=#{CGI::escape(i.last.to_s)}"}.join('&')
	    url = "http://maps.google.#{tld}/maps/api/directions/xml?#{query}"

	    res = open(url).read

      doc = REXML::Document.new(res)

      directions_response = doc.elements['//DirectionsResponse']
      data = directions_response.elements
      data_status = data['.//status']
      data_start_address = data['.//start_address']
      data_end_address = data['.//end_address']
      data_duration_value = data['.//duration/value']
      data_duration_text = data['.//duration/text']
      data_distance_value = data['.//distance/value']
      data_distance_text = data['.//distance/text']

      Directions::Direction.new(
        data_status.nil? ? "" : data_status.text,
        data_start_address.nil? ? "" : data_start_address.text,
        data_end_address.nil? ? "" : data_end_address.text,
        data_duration_value.nil? ? "" : data_duration_value.text,
        data_duration_text.nil? ? "" : data_duration_text.text,
        data_distance_value.nil? ? "" : data_distance_value.text,
        data_distance_text.nil? ? "" : data_distance_text.text
      )
	  end


	  #A result from the Directions service.
	  class Direction < Struct.new(:status, :start_address,:end_address, :duration_value, :duration_text,:distance_value, :distance_text)
	  end

    
      #Raised when the connection to the service is not possible
      class ConnectionException < StandardError
      end
    end
  end
end
