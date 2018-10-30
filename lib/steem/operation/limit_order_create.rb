class Steem::Operation::LimitOrderCreate < Steem::Operation
  def_attr owner: :string
  def_attr orderid: :uint32
  def_attr amount_to_sell: :amount
  def_attr min_to_receive: :amount
  def_attr fill_or_kill: :boolean
  def_attr expiration: :point_in_time
end
