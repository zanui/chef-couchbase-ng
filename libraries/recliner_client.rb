require 'json'
require 'net/http'
require 'uri'

module Recliner
  module Client
    private

    def uri_from_path(path)
      URI.parse "http://#{username}:#{password}@#{hostname}:8091/#{path}"
    end

    def post(path, params)
      response = Net::HTTP.post_form(uri_from_path(path), params)
    end

    def get(path)
      uri = uri_from_path path
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 1
      http.read_timeout = 1
      request = Net::HTTP::Get.new uri.path
      request.basic_auth uri.user, uri.password
      http.request request
    end
  end
end
