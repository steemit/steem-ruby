class Steem::Operation::CustomJson < Steem::Operation
  def_attr required_auths: :required_auths
  def_attr required_posting_auths: :required_auths
  def_attr id: :string
  def_attr json: :string
end
