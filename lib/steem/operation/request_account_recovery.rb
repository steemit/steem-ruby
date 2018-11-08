class Steem::Operation::RequestAccountRecovery < Steem::Operation
  def_attr recovery_account: :string
  def_attr account_to_recover: :string
  def_attr new_owner_authority: :authority
  def_attr extensions: :empty_array
end
