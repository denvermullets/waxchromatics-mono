require 'csv'

class ProcessCollectionImportJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 500

  def perform(collection_import_id)
    import = CollectionImport.find(collection_import_id)
    import.update!(status: 'processing')

    rows = []
    total = 0
    now = Time.current

    CSV.foreach(import.file_path, headers: true) do |csv_row|
      total += 1
      rows << build_row_attributes(import, csv_row, now)

      if rows.size >= BATCH_SIZE
        CollectionImportRow.insert_all(rows)
        rows.clear
      end
    end

    CollectionImportRow.insert_all(rows) if rows.any?
    import.update!(total_rows: total)

    import.collection_import_rows.find_each do |row|
      ImportCollectionRowJob.perform_later(row.id, 0)
    end

    cleanup_file(import.file_path)
  end

  def cleanup_file(path)
    return if path.blank?

    imports_dir = Rails.root.join('tmp', 'imports').to_s
    resolved = File.expand_path(path)
    return unless resolved.start_with?(imports_dir)

    FileUtils.rm_f(resolved)
  end

  private

  def build_row_attributes(import, csv_row, now)
    {
      collection_import_id: import.id,
      discogs_release_id: csv_row['release_id']&.to_i,
      artist_name: csv_row['Artist'],
      title: csv_row['Title'],
      catalog_number: csv_row['Catalog#'],
      label_name: csv_row['Label'],
      media_condition: csv_row['Collection Media Condition'],
      status: 'pending',
      raw_data: csv_row.to_h.to_json,
      created_at: now,
      updated_at: now
    }
  end
end
