module Trades
  class ActivityLog
    attr_reader :trade

    def initialize(trade:)
      @trade = trade
    end

    def entries
      versions = collect_versions
      users = resolve_users(versions)

      versions.map do |version|
        desc = describe(version)
        {
          version: version,
          user: users[version.whodunnit],
          description: desc[:text],
          badge: desc[:badge]
        }
      end
    end

    private

    def collect_versions
      trade_versions = trade.versions.to_a
      item_versions = PaperTrail::Version
                      .where(item_type: 'TradeItem', item_id: trade.trade_items.select(:id))
                      .to_a
      shipment_versions = PaperTrail::Version
                          .where(item_type: 'TradeShipment', item_id: trade.trade_shipments.select(:id))
                          .to_a

      (trade_versions + item_versions + shipment_versions).sort_by(&:created_at)
    end

    def resolve_users(versions)
      user_ids = versions.filter_map(&:whodunnit).uniq
      User.where(id: user_ids).index_by { |user| user.id.to_s }
    end

    def describe(version)
      case version.item_type
      when 'Trade' then describe_trade(version)
      when 'TradeItem' then describe_trade_item(version)
      when 'TradeShipment' then describe_trade_shipment(version)
      else { text: version.event, badge: nil }
      end
    end

    def describe_trade(version)
      text = case version.event
             when 'create'
               'created this trade'
             when 'update'
               trade_update_text(version)
             when 'destroy'
               'deleted this trade'
             end
      { text: text, badge: nil }
    end

    def trade_update_text(version)
      changes = version.object_changes || {}
      if changes.key?('status')
        "changed status to #{changes['status'].last}"
      elsif changes.key?('proposed_by_id')
        're-proposed the trade'
      else
        'updated the trade'
      end
    end

    def describe_trade_item(version)
      release_name = release_name_for(version)
      badge = badge_for(version)
      verb = version.event == 'destroy' ? 'removed' : 'added'
      { text: "#{verb} #{release_name}", badge: badge }
    end

    def describe_trade_shipment(version)
      changes = version.object_changes || {}
      text = case version.event
             when 'create'
               'added shipping info'
             when 'update'
               if changes.key?('status')
                 "updated shipment status to #{changes['status'].last}"
               else
                 'updated shipping info'
               end
             end
      { text: text, badge: :shipping }
    end

    def badge_for(version)
      item_user_id = version_attribute(version, 'user_id')
      return nil unless item_user_id

      item_user_id.to_i == trade.initiator_id ? :offer : :request
    end

    def release_name_for(version)
      release_id = version_attribute(version, 'release_id')
      return 'an item' unless release_id

      release = Release.includes(:artist).find_by(id: release_id)
      return 'an item' unless release

      release.artist ? "#{release.artist.name} - #{release.title}" : release.title
    end

    def version_attribute(version, attr)
      obj = if version.event == 'destroy'
              version.object
            else
              (version.object_changes || {}).transform_values(&:last)
            end
      obj&.dig(attr)
    end
  end
end
