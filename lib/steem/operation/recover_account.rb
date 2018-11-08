class Steem::Operation::RecoverAccount < Steem::Operation
  def_attr account_to_recover: :string
  def_attr new_owner_authority: :authority
  def_attr recent_owner_authority: :authority
  def_attr extensions: :empty_array
end
