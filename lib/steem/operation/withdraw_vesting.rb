class Steem::Operation::WithdrawVesting < Steem::Operation
  def_attr account: :string
  def_attr vesting_shares: :amount
end
