# frozen_string_literal: true

module RSpotify::CustomExtensions::Caching
  extend ActiveSupport::Concern

  include FindCache
  # include AutoCache
end
