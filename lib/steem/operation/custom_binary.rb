class Steem::Operation::CustomBinary < Steem::Operation
  def_attr required_owner_auths: :required_auths
  def_attr required_active_auths: :required_auths
  def_attr required_posting_auths: :required_auths
  def_attr required_auths: :required_auths
  def_attr id: :string
  def_attr data: :raw_bytes
end
