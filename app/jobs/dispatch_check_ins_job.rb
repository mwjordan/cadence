class DispatchCheckInsJob < ApplicationJob
  def perform
    Commitment.due.find_each { |commitment| commitment.dispatch! }
  end
end
