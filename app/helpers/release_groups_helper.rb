module ReleaseGroupsHelper
  BROWSE_PARAMS = %i[sort view letter q format_filter decade label genre country colored page].freeze

  def browse_params(**overrides)
    current = params.permit(*BROWSE_PARAMS).to_h.symbolize_keys
    merged = current.merge(overrides)
    merged.reject { |_, v| v.blank? }
  end

  def browse_pill_class(param_name, value)
    active = params[param_name].to_s == value.to_s
    if active
      'border-crusta-400 text-crusta-400'
    else
      'border-woodsmoke-700 text-woodsmoke-400 hover:border-woodsmoke-500 hover:text-woodsmoke-200'
    end
  end
end
