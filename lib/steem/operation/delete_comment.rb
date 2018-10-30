class Steem::Operation::DeleteComment < Steem::Operation
  def_attr author: :string
  def_attr permlink: :string
end
