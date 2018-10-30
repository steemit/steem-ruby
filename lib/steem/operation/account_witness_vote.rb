class Steem::Operation::AccountWitnessVote < Steem::Operation
  def_attr account: :string
  def_attr witness: :string
  def_attr approve: :boolean
end
