class Steem::Operation::Convert < Steem::Operation
  def_attr owner: :string
  def_attr requestid: :uint32
  def_attr amount: :amount
end
