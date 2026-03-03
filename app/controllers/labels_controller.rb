class LabelsController < ApplicationController
  DISCOGRAPHY_PER_PAGE = 25

  def show
    label = Label.find(params[:id])
    paginate = ->(scope) { pagy(:offset, scope, limit: DISCOGRAPHY_PER_PAGE, page_key: 'page') }

    result = Labels::ShowQuery.new(label: label, user: Current.user, paginate: paginate).call

    %i[label parent_label sub_labels release_count sections collection_counts].each do |attr|
      instance_variable_set(:"@#{attr}", result.public_send(attr))
    end
  end
end
