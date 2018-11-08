class Steem::Operation::SetWithdrawVestingRoute < Steem::Operation
  def_attr from: :string
  def_attr to: :string
  def_attr percent: :uint16
  def_attr auto_vest: :boolean
end
