class Steem::Operation::EscrowRelease < Steem::Operation
  def_attr from: :string
  def_attr to: :string
  def_attr agent: :string
  def_attr who: :string
  def_attr receiver: :string
  def_attr escrow_id: :uint32
  def_attr sbd_amount: :amount
  def_attr steem_amount: :amount
end
