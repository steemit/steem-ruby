class Steem::Operation::FeedPublish < Steem::Operation
  def_attr publisher: :string
  def_attr exchange_rate: :price
end
