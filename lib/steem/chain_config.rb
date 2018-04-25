module Steem
  module ChainConfig
    EXPIRE_IN_SECS = 600
    EXPIRE_IN_SECS_PROPOSAL = 24 * 60 * 60
    
    NETWORKS_STEEM_CHAIN_ID = '0000000000000000000000000000000000000000000000000000000000000000'
    NETWORKS_STEEM_ADDRESS_PREFIX = 'STM'
    NETWORKS_STEEM_CORE_ASSET = ["0", 3, "@@000000021"] # STEEM
    NETWORKS_STEEM_DEBT_ASSET = ["0", 3, "@@000000013"] # SBD
    NETWORKS_STEEM_VEST_ASSET = ["0", 6, "@@000000037"] # VESTS
    NETWORKS_STEEM_DEFAULT_NODE = 'https://api.steemit.com'
    # NETWORKS_STEEM_DEFAULT_NODE = 'https://api.steemitstage.com' # √
    # NETWORKS_STEEM_DEFAULT_NODE = 'https://api.steemitdev.com' # √
    # NETWORKS_STEEM_DEFAULT_NODE = 'https://appbasetest.timcliff.com'
    # NETWORKS_STEEM_DEFAULT_NODE = 'https://gtg.steem.house:8090'
    # NETWORKS_STEEM_DEFAULT_NODE = 'https://api.steem.house' # √?
    # NETWORKS_STEEM_DEFAULT_NODE = 'https://seed.bitcoiner.me'
    # NETWORKS_STEEM_DEFAULT_NODE = 'https://steemd.minnowsupportproject.org'
    # NETWORKS_STEEM_DEFAULT_NODE = 'https://steemd.privex.io'
    # NETWORKS_STEEM_DEFAULT_NODE = 'https://rpc.steemliberator.com'
    # NETWORKS_STEEM_DEFAULT_NODE = 'https://rpc.curiesteem.com'
    # NETWORKS_STEEM_DEFAULT_NODE = 'https://rpc.buildteam.io'
    # NETWORKS_STEEM_DEFAULT_NODE = 'https://steemd.pevo.science'
    # NETWORKS_STEEM_DEFAULT_NODE = 'https://rpc.steemviz.com'
    # NETWORKS_STEEM_DEFAULT_NODE = 'https://steemd.steemgigs.org'
    
    NETWORKS_TEST_CHAIN_ID = '46d82ab7d8db682eb1959aed0ada039a6d49afa1602491f93dde9cac3e8e6c32'
    NETWORKS_TEST_ADDRESS_PREFIX = 'TST'
    NETWORKS_TEST_CORE_ASSET = ["0", 3, "@@000000021"] # TESTS
    NETWORKS_TEST_DEBT_ASSET = ["0", 3, "@@000000013"] # TBD
    NETWORKS_TEST_VEST_ASSET = ["0", 6, "@@000000037"] # VESTS
    NETWORKS_TEST_DEFAULT_NODE = 'https://testnet.steemitdev.com'
    
    NETWORK_CHAIN_IDS = [NETWORKS_STEEM_CHAIN_ID, NETWORKS_TEST_CHAIN_ID]
  end
end
