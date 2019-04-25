module RSpotify
  module DistanceMetrics
    class TrackSimilarity
      def distance(t1, t2)
        return 0 if t1.album == t2.album
        1 - (t1.artists & t2.artists).count.to_f / (t1.artists | t2.artists).count
      end
    end
  end
end
