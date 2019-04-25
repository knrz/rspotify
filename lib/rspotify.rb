require 'rspotify/connection'
require 'rspotify/version'

module RSpotify
  autoload :Album,              'rspotify/album'
  autoload :Artist,             'rspotify/artist'
  autoload :AudioFeatures,      'rspotify/audio_features'
  autoload :Base,               'rspotify/base'
  autoload :Category,           'rspotify/category'
  autoload :Device,             'rspotify/device'
  autoload :Player,             'rspotify/player'
  autoload :Playlist,           'rspotify/playlist'
  autoload :Recommendations,    'rspotify/recommendations'
  autoload :RecommendationSeed, 'rspotify/recommendation_seed'
  autoload :Track,              'rspotify/track'
  autoload :TrackLink,          'rspotify/track_link'
  autoload :User,               'rspotify/user'
  autoload :DistanceMetrics,    'rspotify/distance_metrics'
  autoload :Extensions,         'rspotify/extensions'
  autoload :Extensions

  def self.parse_url(url)
    parts = URI(url).path[1..-1].split("/")
    args = [parts[-1]] # id
    args.unshift(parts[-3]) if parts.count > 2
    return [parts[-2], args]
  end

  def self.find(urls)
    grouped = Array(urls).
                map { |url| parse_url(url) }.
                group_by(&:first).
                transform_values(&:last)
    response = grouped.map do |type, id|
      [type, RSpotify.const_get(type.classify).find(*id)]
    end
    return response.first.last if response.count == 1
    response.to_h
  end
end
