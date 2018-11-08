class Steem::Operation::TransferFromSavings < Steem::Operation
  def_attr from: :string
  def_attr request_id: :uint32
  def_attr to: :string
  def_attr amount: :amount
  def_attr memo: :string
end
