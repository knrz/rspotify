# frozen_string_literal: true

require 'addressable'
require 'base64'
require 'json'
require 'restclient'

module RSpotify
  class MissingAuthentication < StandardError; end

  begin
    API_URI       = 'https://api.spotify.com/v1/'
    AUTHORIZE_URI = 'https://accounts.spotify.com/authorize'
    TOKEN_URI     = 'https://accounts.spotify.com/api/token'
    VERBS         = %w[get post put delete].freeze
  end unless defined?(API_URI) && defined?(AUTHORIZE_URI) && defined?(TOKEN_URI) && defined?(VERBS)

  class << self
    attr_accessor :raw_response
    attr_accessor :client_id, :client_secret, :client_token
    attr_accessor :store_record, :cache_ttl, :store_ttl

    # Authenticates access to restricted data. Requires {https://developer.spotify.com/my-applications user credentials}
    #
    # @param client_id [String]
    # @param client_secret [String]
    #
    # @example
    #           RSpotify.authenticate("<your_client_id>", "<your_client_secret>")
    #
    #           playlist = RSpotify::Playlist.find('wizzler', '00wHcTN0zQiun4xri9pmvX')
    #           playlist.name #=> "Movie Soundtrack Masterpieces"
    def authenticate(client_id, client_secret)
      @client_id, @client_secret = client_id, client_secret
      request_body = { grant_type: 'client_credentials' }
      response = RestClient.post(TOKEN_URI, request_body, auth_header)
      @client_token = JSON.parse(response)['access_token']
      true
    end

    VERBS.each do |verb|
      define_method verb do |path, *params|
        params << { 'Authorization' => "Bearer #{client_token}" } if client_token
        send_request(verb, path, *params)
      end
    end

    def get_without_cache(path, *params)
      params << { 'Authorization' => "Bearer #{client_token}" } if client_token
      send_request('get', path, *params)
    end

    def get_with_cache(path)
      cache_miss = false
      result = Rails.cache.fetch(path, expires_in: cache_ttl) do
        cache_miss = true

        if (response = get_from_store(path)).present?
          Rails.logger.debug('Store hit', path: path)
          return response
        end

        response = get_without_cache(path) # call the original get method
        store_record&.upsert!(path: path, response: response)
        Rails.logger.debug('Store upsert', path: path)
        response
      end
      Rails.logger.debug('Cache hit', path: path) unless cache_miss
      result
    end

    def get_from_store(path)
      store_record&
        .where(path: path)&
        .where('updated_at >= ?', store_ttl.ago)&
        .limit(1)&
        .pluck(:response)&
        .first
    end

    alias get get_with_cache

    def resolve_auth_request(user_id, url)
      users_credentials = if User.class_variable_defined?('@@users_credentials')
                            User.class_variable_get('@@users_credentials')
                          end

      if users_credentials && users_credentials[user_id]
        User.oauth_get(user_id, url)
      else
        get(url)
      end
    end

    private

    def send_request(verb, path, *params)
      url = path.start_with?('http') ? path : API_URI + path
      url, query = *url.split('?')
      url = Addressable::URI.encode(url)
      url << "?#{query}" if query

      begin
        headers = get_headers(params)
        headers['Accept-Language'] = ENV['ACCEPT_LANGUAGE'] if ENV['ACCEPT_LANGUAGE']
        response = RestClient.send(verb, url, *params)
      rescue RestClient::Unauthorized => e
        raise e if request_was_user_authenticated?(*params)

        raise MissingAuthentication unless @client_token

        authenticate(@client_id, @client_secret)

        headers = get_headers(params)
        headers['Authorization'] = "Bearer #{@client_token}"

        response = retry_connection(verb, url, params)
      end

      return response if raw_response
      JSON.parse(response) unless response.nil? || response.empty?
    end

    # Added this method for testing
    def retry_connection(verb, url, params)
      RestClient.send(verb, url, *params)
    end

    def request_was_user_authenticated?(*params)
      users_credentials = if User.class_variable_defined?('@@users_credentials')
                            User.class_variable_get('@@users_credentials')
                          end

      headers = get_headers(params)
      !!users_credentials&.any? { |_user_id, creds| "Bearer #{creds['token']}" == headers['Authorization'] }
    end

    def auth_header
      authorization = Base64.strict_encode64("#{@client_id}:#{@client_secret}")
      { 'Authorization' => "Basic #{authorization}" }
    end

    def get_headers(params)
      params.find { |param| param.is_a?(Hash) && param['Authorization'] }
    end
  end
end
