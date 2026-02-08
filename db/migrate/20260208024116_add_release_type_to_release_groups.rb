class AddReleaseTypeToReleaseGroups < ActiveRecord::Migration[8.1]
  def up
    add_column :release_groups, :release_type, :string, default: "Album", null: false
    add_index :release_groups, :release_type

    ReleaseGroup.reset_column_information

    ReleaseGroup.find_each do |rg|
      descriptions = rg.releases
                       .joins(:release_formats)
                       .pluck("release_formats.descriptions")
                       .compact

      keywords = descriptions.flat_map { |d| d.split("; ") }
      rg.update_column(:release_type, classify_type(keywords))
    end
  end

  def down
    remove_column :release_groups, :release_type
  end

  private

  def classify_type(keywords)
    votes = keywords.map { |kw| keyword_to_type(kw) }.compact
    return "Album" if votes.empty?

    votes.tally.max_by { |_type, count| count }.first
  end

  def keyword_to_type(keyword)
    case keyword
    when "Compilation"
      "Compilation"
    when /\bEP\b/, "Mini-Album"
      "EP"
    when "Single", "Maxi-Single"
      "Single"
    when "Album", "LP"
      "Album"
    end
  end
end
