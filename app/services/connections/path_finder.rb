module Connections
  class PathFinder < Service
    MAX_DEPTH = 6
    BATCH_SIZE = 100

    def initialize(artist_a_id:, artist_b_id:)
      @artist_a_id = artist_a_id.to_i
      @artist_b_id = artist_b_id.to_i
    end

    def call
      return error_result('Please select two different artists') if @artist_a_id == @artist_b_id

      artist_a = Artist.find_by(id: @artist_a_id)
      artist_b = Artist.find_by(id: @artist_b_id)
      return error_result('Artist not found') unless artist_a && artist_b

      cached = ConnectionCache.lookup(@artist_a_id, @artist_b_id)
      return build_cached_result(cached, artist_a, artist_b) if cached

      result = bfs(artist_a, artist_b)
      cache_result(result)
      result
    end

    private

    def bfs(artist_a, artist_b)
      visited = { artist_a.id => nil }
      queue = [artist_a.id]

      MAX_DEPTH.times do
        break if queue.empty? || visited.key?(artist_b.id)

        queue = expand_level(queue, visited, artist_b.id)
      end

      build_result(artist_a, artist_b, visited)
    end

    def expand_level(queue, visited, target_id)
      next_queue = []

      queue.each_slice(BATCH_SIZE) do |batch|
        NeighborQuery.call(batch).each_value do |edges|
          edges.each do |edge|
            next if visited.key?(edge[:neighbor_id])

            visited[edge[:neighbor_id]] = edge.slice(:from_id, :release_id, :role)
            next_queue << edge[:neighbor_id]
          end

          break if visited.key?(target_id)
        end

        break if visited.key?(target_id)
      end

      next_queue
    end

    def build_result(artist_a, artist_b, visited)
      unless visited.key?(artist_b.id)
        return { found: false, degrees: nil, shortest_path: [], alternate_paths: [],
                 artist_a: artist_a, artist_b: artist_b }
      end

      path = reconstruct_path(artist_b.id, visited)
      PathEnricher.call(path)

      { found: true, degrees: path.length, shortest_path: path,
        alternate_paths: [], artist_a: artist_a, artist_b: artist_b }
    end

    def reconstruct_path(end_id, visited)
      path = []
      current = end_id

      while visited[current]
        edge = visited[current]
        path.unshift(from_artist_id: edge[:from_id], to_artist_id: current,
                     release_id: edge[:release_id], role: edge[:role])
        current = edge[:from_id]
      end

      path
    end

    def build_cached_result(cached, artist_a, artist_b)
      unless cached.found
        return { found: false, degrees: nil, shortest_path: [], alternate_paths: [],
                 artist_a: artist_a, artist_b: artist_b }
      end

      path = cached.oriented_path(@artist_a_id)
      PathEnricher.call(path)

      { found: true, degrees: cached.degrees, shortest_path: path,
        alternate_paths: [], artist_a: artist_a, artist_b: artist_b }
    end

    def cache_result(result)
      return if result[:error]

      ConnectionCache.store(
        @artist_a_id, @artist_b_id,
        found: result[:found],
        degrees: result[:degrees],
        path_data: raw_path_data(result[:shortest_path])
      )
    end

    def raw_path_data(path)
      path.map do |edge|
        {
          from_artist_id: edge[:from_artist_id],
          to_artist_id: edge[:to_artist_id],
          release_id: edge[:release_id],
          role: edge[:role]
        }
      end
    end

    def error_result(message)
      { found: false, error: message }
    end
  end
end
