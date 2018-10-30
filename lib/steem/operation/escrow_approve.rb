class Steem::Operation::EscrowApprove < Steem::Operation
  def_attr from: :string
  def_attr to: :string
  def_attr agent: :string
  def_attr who: :string
  def_attr escrow_id: :uint32
  def_attr approve: :boolean
end
