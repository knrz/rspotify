# frozen_string_literal: true

module RSpotify::CustomExtensions::Stream
  extend ActiveSupport::Concern

  def stream(method, method_params = {})
    self.class.stream(self, method, method_params)
  end

  def track_stream(method, method_params = {})
    self.class.track_stream(self, method, method_params)
  end

  module ClassMethods
    def find_in_batches(ids)
      Enumerator.new do |generator|
        ids.each_slice(20) do |bunch|
          find(bunch).each { |item| generator << item }
        end
      end.lazy
    end

    def stream_methods(methods = {})
      methods.each do |method_name, page_limit|
        default_params = { page_limit: page_limit }

        define_method("all_#{method_name}") do |params = {}|
          self.class.stream(self, method_name, default_params.merge(params))
        end
      end
    end

    def stream(source, method_name, method_params = {})
      page_limit = method_params.delete(:page_limit) || 100
      offset = 0
      next_batch = lambda do
        params = method_params.merge(limit: page_limit, offset: offset)
        params.delete(:offset) if offset.zero?
        offset += page_limit
        source.public_send(method_name, **params)
      rescue StandardError
        Rails.logger.error($ERROR_INFO)
        []
      end

      Enumerator.new do |generator|
        while (items = next_batch.call).present?
          items.each { |item| generator << item }
        end
      end.lazy
    end

    def track_stream(source, method_name, method_params = {})
      Enumerator.new do |generator|
        stream(source, method_name, method_params).each do |item|
          case item
          when RSpotify::Track
            generator << item
          else
            stream(item, :tracks).each do |track|
              generator << track
            end
          end
        end
      end
    end
  end
end
