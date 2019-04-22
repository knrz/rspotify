# coding: utf-8
module RSpotify
  module DistanceMetrics
    class TrackVector
      def initialize(track)
        @track = track
      end

      def album
        @track.album.id
      end

      def artists
        @track.artists.map(&:id).to_set
      end
    end

    class TrackSimilary
      def distance(t1, t2)
        return 0 if t1.album == t1.album
        1 - (t1.artists & t2.artists).count.to_f / (t1.artists | t2.artists).count
      end
    end
  end
end
