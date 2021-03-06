require 'ym4r/google_maps/api_key'
require 'open-uri'
require 'rexml/document'
require 'cgi'

module Ym4r
  module GoogleMaps
	module Geocoding

	  GEO_SUCCESS = 200
	  GEO_MISSING_ADDRESS = 601
	  GEO_UNKNOWN_ADDRESS = 602
	  GEO_UNAVAILABLE_ADDRESS = 603
	  GEO_BAD_KEY = 610
	  GEO_TOO_MANY_QUERIES = 620
	  GEO_SERVER_ERROR = 500
	  
	  #Gets placemarks by querying the Google Maps Geocoding service with the +request+ string. Options can either an explicity GMaps API key (<tt>:key</tt>) or a host, (<tt>:host</tt>). 
	  def self.get(request,options = {})
	    api_key = options[:key]
	    output =  options[:output] || "kml"
	    url = "http://maps.google.com/maps/geo?q=#{CGI::escape(request)}&key=#{api_key}&output=#{output}"

	    res = open(url).read

	    case output.to_sym
	    when :json
	      res = eval(res.gsub(":","=>")) #!!!EVAL EVAL EVAL EVAL!!! hopefully we can trust google...
	      placemarks = Placemarks.new(res['name'],res['Status']['code'])
	      if res['Placemark']
	        placemark = res['Placemark']
	        
	        placemark.each do |data|
	          
	          data_country = data['Country']['CountryNameCode'] rescue ""
	          data_administrative = data['Country']['AdministrativeArea']['AdministrativeAreaName'] rescue ""
	          data_sub_administrative = data['Country']['AdministrativeArea']['SubAdministrativeArea']['SubAdministrativeAreaName'] rescue ""
	          data_locality = data['Country']['AdministrativeArea']['SubAdministrativeArea']['Locality']['LocalityName'] rescue ""
	          data_dependent_locality = data['Country']['AdministrativeArea']['SubAdministrativeArea']['Locality']['DependentLocality']['DependentLocalityName'] rescue ""
	          data_thoroughfare = data['Country']['AdministrativeArea']['SubAdministrativeArea']['Locality']['DependentLocality']['Thoroughfare']['ThoroughfareName'] rescue ""
	          data_postal_code = data['Country']['AdministrativeArea']['SubAdministrativeArea']['Locality']['DependentLocality']['Thoroughfare']['PostalCode']['PostalCodeNumber'] rescue ""
	          lon, lat = data['Point']['coordinates'][0,2]
	          data_accuracy = data['Accuracy']
	          unless data_accuracy.nil?
	            data_accuracy = data_accuracy.to_i
	          end
	          
	          placemarks << Geocoding::Placemark.new(data['address'],
	                                                 data_country,
	                                                 data_administrative,
	                                                 data_sub_administrative,
	                                                 data_locality,
	                                                 data_dependent_locality,
	                                                 data_thoroughfare,
	                                                 data_postal_code,
	                                                 lon, lat, data_accuracy)
	          
	        end
	      end
	    when :kml, :xml
	      
	      doc = REXML::Document.new(res) 

	      response = doc.elements['//Response']
	      placemarks = Placemarks.new(response.elements['name'].text,response.elements['Status/code'].text.to_i)
	      response.elements.each(".//Placemark") do |placemark|
	        data = placemark.elements
	        data_country = data['.//CountryNameCode']
	        data_administrative = data['.//AdministrativeAreaName']
	        data_sub_administrative = data['.//SubAdministrativeAreaName']
	        data_locality = data['.//LocalityName']
	        data_dependent_locality = data['.//DependentLocalityName']
	        data_thoroughfare = data['.//ThoroughfareName']
	        data_postal_code = data['.//PostalCodeNumber']
	        lon, lat = data['.//coordinates'].text.split(",")[0..1].collect {|l| l.to_f }
	        data_accuracy = data['.//*[local-name()="AddressDetails"]'].attributes['Accuracy']
	        unless data_accuracy.nil?
	          data_accuracy = data_accuracy.to_i
	        end
	        placemarks << Geocoding::Placemark.new(data['address'].text,
	                                               data_country.nil? ? "" : data_country.text,
	                                               data_administrative.nil? ? "" : data_administrative.text,
	                                               data_sub_administrative.nil? ? "" : data_sub_administrative.text,
	                                               data_locality.nil? ? "" : data_locality.text,
	                                               data_dependent_locality.nil? ? "" : data_dependent_locality.text,
	                                               data_thoroughfare.nil? ? "" : data_thoroughfare.text,
	                                               data_postal_code.nil? ? "" : data_postal_code.text,
	                                               lon, lat, data_accuracy )
	      end
	    end
	    
	    placemarks
	  end

	  #Group of placemarks returned by the Geocoding service. If the result is valid the +status+ attribute should be equal to <tt>Geocoding::GE0_SUCCESS</tt>
	  class Placemarks < Array
	    attr_accessor :name,:status

	    def initialize(name,status)
	      super(0)
	      @name = name
	      @status = status
	    end
	  end

	  #A result from the Geocoding service.
	  class Placemark < Struct.new(:address,:country_code,:administrative_area,:sub_administrative_area,:locality,:dependent_locality,:thoroughfare,:postal_code,:longitude,:latitude,:accuracy)
	    def lonlat
	      [longitude,latitude]
	    end

	    def latlon
	      [latitude,longitude]
	    end
	  end

	  def self.accuracy(code)
	    {0 => "Unknown location",
	     1 => "Country level accuracy",
	     2 => "Region (state, province, prefecture, etc.) level accuracy",
	     3 => "Sub-region (county, municipality, etc.) level accuracy",
	     4 => "Town (city, village) level accuracy",
	     5 => "Post code (zip code) level accuracy",
	     6 => "Street level accuracy",
	     7 => "Intersection level accuracy",
	      8 => "Address level accuracy"}[code]
	    
	  end
    
      #Raised when the connection to the service is not possible
      class ConnectionException < StandardError
      end
    end
  end
end
