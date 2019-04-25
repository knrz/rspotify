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

  def self.parse_url(url)
    parts = URI(url).path[1..-1].split("/")
    args = [parts[-1]] # id
    args.unshift(parts[-3]) if parts.count > 2
    return [parts[-2], args]
  end

  def self.find(urls)
    grouped = Array(urls).
                map { |url| RSpotify.parse_url(url) }.
                group_by(&:first).
                transform_values { |values| values.map(&:last) }
    response = grouped.map do |type, ids|
      resource = RSpotify.const_get(type.classify)
      [type, ids.map { |id| resource.find(*id) }]
    end
    if response.count == 1
      response = response.first.last
      response.try(:count) == 1 ? response.first : response
    else
      response.to_h
    end
  end
end
