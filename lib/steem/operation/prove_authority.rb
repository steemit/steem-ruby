class Steem::Operation::ProveAuthority < Steem::Operation
  def_attr challenged: :string
  def_attr require_owner: :boolean
end
