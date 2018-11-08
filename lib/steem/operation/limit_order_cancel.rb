class Steem::Operation::LimitOrderCancel < Steem::Operation
  def_attr owner: :string
  def_attr orderid: :uint32
end
