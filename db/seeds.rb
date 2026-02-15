# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# --- Trade seeds ---
# Only run if we have at least two users with collection items
if User.count >= 2
  users = User.limit(2).to_a
  user_a, user_b = users

  collection_a = user_a.default_collection.collection_items.includes(:release).limit(3)
  collection_b = user_b.default_collection.collection_items.includes(:release).limit(3)

  if collection_a.any? && collection_b.any?
    # Draft trade
    unless Trade.involving(user_a).with_status("draft").exists?
      trade = Trade.create!(initiator: user_a, recipient: user_b, status: "draft", notes: "Interested in swapping?")
      ci = collection_a.first
      trade.trade_items.create!(user: user_a, release: ci.release, collection_item: ci)
      if (ci_b = collection_b.first)
        trade.trade_items.create!(user: user_b, release: ci_b.release, collection_item: ci_b)
      end
      puts "Created draft trade ##{trade.id}"
    end

    # Proposed trade
    unless Trade.involving(user_a).with_status("proposed").exists?
      trade = Trade.create!(initiator: user_a, recipient: user_b, status: "proposed",
                            notes: "How about this?", proposed_at: 1.day.ago)
      if (ci = collection_a.second)
        trade.trade_items.create!(user: user_a, release: ci.release, collection_item: ci)
      end
      if (ci_b = collection_b.second)
        trade.trade_items.create!(user: user_b, release: ci_b.release, collection_item: ci_b)
      end
      puts "Created proposed trade ##{trade.id}"
    end

    # Accepted trade
    unless Trade.involving(user_a).with_status("accepted").exists?
      trade = Trade.create!(initiator: user_b, recipient: user_a, status: "accepted",
                            notes: "Deal!", proposed_at: 3.days.ago, responded_at: 2.days.ago)
      if (ci = collection_a.third)
        trade.trade_items.create!(user: user_a, release: ci.release, collection_item: ci)
      end
      if (ci_b = collection_b.third)
        trade.trade_items.create!(user: user_b, release: ci_b.release, collection_item: ci_b)
      end
      puts "Created accepted trade ##{trade.id}"
    end
  else
    puts "Skipping trade seeds: users need collection items first"
  end
else
  puts "Skipping trade seeds: need at least 2 users"
end
