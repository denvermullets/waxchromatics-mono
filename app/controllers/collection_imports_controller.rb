class CollectionImportsController < ApplicationController
  def new
    @collection_import = CollectionImport.new
  end

  def create
    file = params[:file]

    unless file.present? && file.content_type == 'text/csv'
      redirect_to new_collection_import_path, alert: 'Please upload a valid CSV file.'
      return
    end

    dest = save_csv(file)
    import = Current.user.collection_imports.create!(
      filename: file.original_filename,
      file_path: dest.to_s,
      status: 'pending'
    )

    ProcessCollectionImportJob.perform_later(import.id)
    redirect_to collection_import_path(import), notice: 'Import started! Processing your CSV in the background.'
  end

  private

  def save_csv(file)
    dir = Rails.root.join('tmp', 'imports')
    FileUtils.mkdir_p(dir)
    dest = dir.join("#{SecureRandom.uuid}.csv")
    File.binwrite(dest, file.read)
    dest
  end

  def show
    @import = Current.user.collection_imports.find(params[:id])
    @completed_rows = @import.collection_import_rows.where(status: 'completed').order(:id)
    @in_progress_rows = @import.collection_import_rows.where(status: %w[pending ingesting]).order(:id)
    @failed_rows = @import.collection_import_rows.where(status: 'failed').order(:id)
  end
end
