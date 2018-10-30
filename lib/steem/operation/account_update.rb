class Steem::Operation::AccountUpdate < Steem::Operation
  def_attr account: :string
  def_attr owner: :optional_authority
  def_attr active: :optional_authority
  def_attr posting: :optional_authority
  def_attr memo_key: :public_key
  def_attr json_metadata: :string
end
