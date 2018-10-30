class Steem::Operation::WitnessUpdate < Steem::Operation
  def_attr owner: :string
  def_attr url: :string
  def_attr block_signing_key: :public_key
  def_attr props: :chain_properties
  def_attr fee: :amount
end
