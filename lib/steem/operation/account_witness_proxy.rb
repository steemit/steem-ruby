class Steem::Operation::AccountWitnessProxy < Steem::Operation
  def_attr account: :string
  def_attr proxy: :string
end
