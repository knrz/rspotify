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
  end
end
