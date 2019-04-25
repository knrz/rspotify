# frozen_string_literal: true

module RSpotify
  module CustomExtensions
    module FindCache
      extend ActiveSupport::Concern

      module ClassMethods
        def find_many(ids, type, market: nil)
          ids.map do |id|
            find_one(id, type, market: market)
          end
        end

        def find_one(id, type, market: nil)
          type_class = RSpotify.const_get(type.capitalize)
          path = "#{type}s/#{id}"
          path << "?market=#{market}" if market

          response = RSpotify.get(path)
          type_class.new(response) if response.present?
        end
      end
    end
  end
end
