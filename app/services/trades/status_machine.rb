module Trades
  class StatusMachine
    TRANSITIONS = {
      'draft' => { 'propose' => 'proposed', 'cancel' => 'cancelled' },
      'proposed' => { 'accept' => 'accepted', 'decline' => 'declined', 'cancel' => 'cancelled' }
    }.freeze

    attr_reader :trade, :user, :action, :error

    def initialize(trade:, user:, action:)
      @trade = trade
      @user = user
      @action = action
      @error = nil
    end

    def call
      unless permitted?
        @error = "You don't have permission to #{action} this trade"
        return false
      end

      new_status = TRANSITIONS.dig(trade.status, action)
      unless new_status
        @error = "Cannot #{action} a trade that is #{trade.status}"
        return false
      end

      apply_transition(new_status)
    end

    private

    def apply_transition(new_status)
      trade.status = new_status
      stamp_timestamps
      trade.save
    end

    def stamp_timestamps
      if action == 'propose'
        trade.proposed_at = Time.current
        trade.proposed_by = user
      end
      trade.responded_at = Time.current if %w[accept decline].include?(action)
    end

    def permitted?
      case action
      when 'propose' then initiator?
      when 'accept', 'decline' then non_proposer?
      when 'cancel' then trade.draft? ? initiator? : proposer?
      else false
      end
    end

    def initiator?
      trade.initiator_id == user.id
    end

    def proposer?
      trade.proposed_by_id == user.id
    end

    def non_proposer?
      trade.participant?(user) && !proposer?
    end
  end
end
