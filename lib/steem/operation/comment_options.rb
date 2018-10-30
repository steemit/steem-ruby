class Steem::Operation::CommentOptions < Steem::Operation
  def_attr author: :string
  def_attr permlink: :string
  def_attr max_accepted_payout: :amount
  def_attr percent_steem_dollars: :uint32
  def_attr allow_replies: :boolean
  def_attr allow_votes: :boolean
  def_attr allow_curation_rewards: :boolean
  def_attr extensions: :comment_options_extensions
end
