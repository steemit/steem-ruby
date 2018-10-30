class Steem::Operation::EscrowDispute < Steem::Operation
  def_attr from: :string
  def_attr to: :string
  def_attr agent: :string
  def_attr who: :string
  def_attr escrow_id: :uint32
end
