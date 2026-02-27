class ConnectionCache < ApplicationRecord
  belongs_to :artist_a, class_name: 'Artist'
  belongs_to :artist_b, class_name: 'Artist'

  validate :artist_a_id_less_than_artist_b_id

  def self.lookup(id1, id2)
    a, b = [id1.to_i, id2.to_i].sort
    find_by(artist_a_id: a, artist_b_id: b)
  end

  def self.store(id1, id2, found:, degrees:, path_data:)
    a, b = [id1.to_i, id2.to_i].sort
    upsert(
      {
        artist_a_id: a, artist_b_id: b,
        found: found, degrees: degrees, path_data: path_data,
        created_at: Time.current, updated_at: Time.current
      },
      unique_by: %i[artist_a_id artist_b_id]
    )
  end

  def self.invalidate_for_artist(artist_id)
    where(artist_a_id: artist_id).or(where(artist_b_id: artist_id)).delete_all
  end

  def self.invalidate_pair(id1, id2)
    a, b = [id1.to_i, id2.to_i].sort
    where(artist_a_id: a, artist_b_id: b).delete_all
  end

  def oriented_path(start_id)
    edges = path_data.map(&:deep_symbolize_keys)
    return edges if edges.empty?

    if edges.first[:from_artist_id] == start_id.to_i
      edges
    else
      edges.reverse.map do |edge|
        {
          from_artist_id: edge[:to_artist_id],
          to_artist_id: edge[:from_artist_id],
          release_id: edge[:release_id],
          role: edge[:role]
        }
      end
    end
  end

  private

  def artist_a_id_less_than_artist_b_id
    return unless artist_a_id && artist_b_id && artist_a_id >= artist_b_id

    errors.add(:base, 'artist_a_id must be less than artist_b_id')
  end
end
