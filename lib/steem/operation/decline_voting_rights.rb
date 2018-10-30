class Steem::Operation::DeclineVotingRights < Steem::Operation
  def_attr account: :string
  def_attr decline: :boolean
end
