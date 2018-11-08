class Steem::Operation::LimitOrderCreate2 < Steem::Operation
  def_attr owner: :string
  def_attr orderid: :uint32
  def_attr amount_to_sell: :amount
  def_attr fill_or_kill: :boolean
  def_attr exchange_rate: :price
  def_attr expiration: :point_in_time
end
