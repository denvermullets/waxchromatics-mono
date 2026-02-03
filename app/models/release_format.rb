class ReleaseFormat < ApplicationRecord
  belongs_to :release

  SINGLE_COLORS = %w[black white red blue green yellow orange purple pink brown gold clear].freeze

  MULTI_COLOR_MAP = {
    %w[black red] => 'black-red-splatter',
    %w[red black] => 'black-red-splatter',
    %w[blue white] => 'blue-white-splatter',
    %w[white blue] => 'blue-white-splatter',
    %w[yellow green white] => 'yellow-green-white-splatter',
    %w[black white] => 'black-white-half',
    %w[white black] => 'black-white-half',
    %w[red blue] => 'red-blue-half',
    %w[blue red] => 'red-blue-half',
    %w[pink black] => 'pink-black-half',
    %w[black pink] => 'pink-black-half',
    %w[green yellow] => 'green-yellow-half',
    %w[yellow green] => 'green-yellow-half',
    %w[purple gold] => 'purple-gold-half',
    %w[gold purple] => 'purple-gold-half'
  }.freeze

  ALIAS_MAP = { 'grey' => 'grey', 'gray' => 'grey', 'silver' => 'grey', 'transparent' => 'clear' }.freeze

  def vinyl_image_path
    "vinyl/#{resolve_svg_name}.svg"
  end

  private

  def resolve_svg_name
    return 'black' if color.blank?

    parts = color.downcase.strip.split(%r{[,/&+]}).map(&:strip).reject(&:blank?)

    parts.size > 1 ? resolve_multi_color(parts) : resolve_single_color(parts.first)
  end

  def resolve_multi_color(parts)
    mapped = parts.map { |p| normalize_single(p) }
    MULTI_COLOR_MAP[mapped] || mapped.find { |c| SINGLE_COLORS.include?(c) } || 'black'
  end

  def resolve_single_color(value)
    single = normalize_single(value)
    SINGLE_COLORS.include?(single) ? single : 'black'
  end

  def normalize_single(value)
    cleaned = value.downcase.strip
    ALIAS_MAP[cleaned] || cleaned
  end
end
