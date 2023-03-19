    // SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import '../../interfaces/IVault.sol';
import '../../account/Account.sol';

struct StorageData {
  uint minimumStake;
  uint stakersCount;
  IERC20 token;
  IVault.Pair[] pairs;
  mapping (address => bool) supportedTokens;
  mapping (address => mapping(address => mapping(address => IVault.Staker))) stakers;
}

library VaultLib {
  using Address for address;
  using Utility for *;
  using SafeMath for uint256;

  event Staked(uint);
  event Unstaked(uint);

  function setRewardToken(StorageData storage self, address _token) internal {
    Address.isContract(_token).assertEqual(true, "Only contract address is allowed");
    self.token = IERC20(_token);
  }

  function setSupportedToken(StorageData storage self, address token) internal {
    if(self.supportedTokens[token]) revert IVault.TokenAlreadySupported(token);
    self.supportedTokens[token] = true;
  }

  function validateId(StorageData storage self, uint pairId) internal view {
    require(pairId < self.pairs.length, "Invalid id");
  }

  function setUpTokenPair(StorageData storage self, address tokenA, address tokenB, uint8 earnRate, uint _minStake) internal {
    bool(earnRate < 101).assertEqual(true, "Rate should be less than 101");
    bool(tokenA != address(0)).assertChained_2(tokenB != address(0), 'TokenA is zero', 'TokenB is zero');
    bool(self.supportedTokens[tokenB]).assertChained_2(self.supportedTokens[tokenA], "TokenB not supported", "TokenA not supported");
    bool(self.supportedTokens[tokenB] && self.supportedTokens[tokenA]).assertEqual(true, "Tokens not supported");
    uint liq = tokenB.getAndCompareAllowance(msg.sender, address(this), _minStake).transferAllowance(tokenB, msg.sender, address(this));
    self.pairs.push(IVault.Pair(tokenA, tokenB, earnRate, _minStake, liq, true));
  }

  function stakeToken(StorageData storage self, uint pairId) internal {
    validateId(self, pairId);
    self.stakersCount ++;
    IVault.Pair memory pr = self.pairs[pairId];
    pr.isOpen.assertEqual(true, "Locked");
    bool(pr.liquidity > 10 * (10 ** 18)).assertEqual(true, "No liquidity for this pair");
    bool(pr.tokenA != address(0)).assertChained_2(pr.tokenB != address(0), "TokenA is zero", "TokenB is zero");
    address to = address(this);
    address alc = self.stakers[msg.sender][pr.tokenA][pr.tokenB].account;
    uint stake = pr.tokenA.getAndCompareAllowance(msg.sender, to, pr.minimumStake).transferAllowance(pr.tokenA, msg.sender, to);
    self.stakers[msg.sender][pr.tokenA][pr.tokenB] = IVault.Staker(_now(), stake, 0, alc);
  }

  function unstakeToken(StorageData storage self, uint pairId) internal {
    validateId(self, pairId);
    IVault.Staker memory stk = getStakeProfile(self, msg.sender);
    IVault.Pair memory pr = self.pairs[pairId];
    stk.stake.assertUintGT(0, "No stake");
    self.stakers[msg.sender][pr.tokenA][pr.tokenB].stake = 0;
    self.stakers[msg.sender][pr.tokenA][pr.tokenB].depositTime = 0;
    pr.tokenA.transferToken(msg.sender, stk.stake);
    uint reward = stk.stake.calculateReward(stk.depositTime, pr.rate);
    if(pr.liquidity < reward) {
      reward = pr.liquidity;
    }
    self.pairs[pairId].liquidity = pr.liquidity.sub(reward);
    if(self.pairs[pairId].liquidity < 10 * (10**18)) {
      self.pairs[pairId].isOpen = false;
    }
    pr.tokenB.transferToken(msg.sender, reward);
  }

  /**@dev Stake Celo for token reward.
   * - The amount of Celo sent along the call must be greater 
   *      than the minimum staking amount.
   * - We check if caller has existing account otherwise we 
   *      create a new account for them.
   * - We can make a dynamic staking i.e stakers can stake any amount
   *      Celo, anytime. Each stake is unique to another in timing and
   *      identity.
   */
  function _stake(StorageData storage self, address who, uint value) private returns(bool){
    address alc;
    IVault.Staker memory stk = getStakeProfile(self, who);
    if(value < self.minimumStake) revert IVault.ZeroValue(value);
    alc = stk.account;
    if(alc == address(0)) {
      alc = address(new Account(self.token));
    }

    if(stk.celoAmount > 0) {
      _unstake(self, alc, stk.celoAmount, stk.depositTime);
    }
    address _k = address(this);
    self.stakers[msg.sender][_k][_k] = IVault.Staker(_now(), 0, value, alc);
    self.stakersCount ++;
    emit Staked(value);

    return true;
  }

  function _unstake(StorageData storage self, address alc, uint value, uint depositTime) private {
    self.stakersCount --;
    address _k = address(this);
    self.stakers[msg.sender][_k][_k].celoAmount = 0;
    self.stakers[msg.sender][_k][_k].depositTime = 0;
    (bool sent,) = alc.call{value: value}("");
    require(sent, "Transfer rejected");
    uint reward = value.calculateReward(depositTime, 60);
    if(reward > 0) alc.mintRewardToken(address(self.token), reward);

    emit Unstaked(value);
  }

  ///@dev deposit $Celo to vault
  function stakeCelo(StorageData storage self, uint msgValue) internal returns(bool) {
    return _stake(self, msg.sender, msgValue);
  }

  ///@dev Stake on behalf of @param who Account to stake for
  function stakeOnBehalf(StorageData storage self, address who, uint value) internal returns(bool) {
    require(msg.sender != who, "please use designated function");
    return _stake(self, who, value);
  }

  /**@dev Unstake Celo from the vault.
   */
  function unstake(StorageData storage self) internal returns(bool) {
    address _k = address(this);
    IVault.Staker memory stk = self.stakers[msg.sender][_k][_k];
    if(stk.celoAmount == 0) revert IVault.NoStakingDetected(stk.celoAmount);
    require(stk.account != address(0), "Account anomally detected");
    _unstake(self, stk.account, stk.celoAmount, stk.depositTime);

    return true;
  }

  ///@dev Returns current unix time stamp
  function _now() internal view returns(uint) {
      return block.timestamp;
  }

  function getStakeProfile(StorageData storage self, address who) internal view returns(IVault.Staker memory) {
    address _k = address(this);
    return self.stakers[who][_k][_k];
  } 

  ///@dev returns account of @param who : any valid address
  function withdraw(StorageData storage self) public {
    address alc = getStakeProfile(self, msg.sender).account;
    IAccount(alc).withdrawCelo(msg.sender);
    IAccount(alc).withdrawERC20(msg.sender);
  }

}