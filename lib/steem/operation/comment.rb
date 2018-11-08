class Steem::Operation::Comment < Steem::Operation
  def_attr parent_author: :string
  def_attr parent_permlink: :string
  def_attr author: :string
  def_attr permlink: :string
  def_attr title: :string
  def_attr body: :string
  def_attr json_metadata: :string
end
