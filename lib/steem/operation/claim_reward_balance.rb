class Steem::Operation::ClaimRewardBalance < Steem::Operation
  def_attr account: :string
  def_attr reward_steem: :amount
  def_attr reward_sbd: :amount
  def_attr reward_vests: :amount
end
