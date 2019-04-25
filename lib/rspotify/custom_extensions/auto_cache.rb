# frozen_string_literal: true

module RSpotify
  module CustomExtensions
    module AutoCache
      BASE_URL = 'https://api.spotify.com/v1/'

      extend ActiveSupport::Concern

      def initialize(options = {})
        super(options).tap do
          path = options.dig('href')&.slice(BASE_URL.length..-1)
          return if path.nil?

          Rails.cache.fetch(path) do
            RSpotify.store_record.upsert!(path: path, response: options)
            options
          end
        end
      end
    end
  end
end
