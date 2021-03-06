class Steem::Operation::AccountCreate < Steem::Operation
  def_attr fee: :amount
  def_attr creator: :string
  def_attr new_account_name: :string
  def_attr owner: :authority
  def_attr active: :authority
  def_attr posting: :authority
  def_attr memo_key: :public_key
  def_attr json_metadata: :string
end
