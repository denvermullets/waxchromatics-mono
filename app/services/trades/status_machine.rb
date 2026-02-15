module Trades
  class StatusMachine
    TRANSITIONS = {
      'draft' => { 'propose' => 'proposed', 'cancel' => 'cancelled' },
      'proposed' => { 'accept' => 'accepted', 'decline' => 'declined', 'cancel' => 'cancelled' }
    }.freeze

    PERMISSIONS = {
      'propose' => :initiator,
      'cancel' => :initiator,
      'accept' => :recipient,
      'decline' => :recipient
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
      trade.proposed_at = Time.current if action == 'propose'
      trade.responded_at = Time.current if %w[accept decline].include?(action)
    end

    def permitted?
      required_role = PERMISSIONS[action]
      return false unless required_role

      case required_role
      when :initiator then trade.initiator_id == user.id
      when :recipient then trade.recipient_id == user.id
      end
    end
  end
end
