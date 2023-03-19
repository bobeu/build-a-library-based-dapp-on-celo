    // SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../interfaces/IERC20Extended.sol";

library Utility {
  using Address for address;
  using SafeMath for uint256;

  // ///@dev Requires the three conditions to be true 
  function assertChained_2(bool a, bool b, string memory errorMessage1, string memory errorMessage2) internal pure {
    require(a, errorMessage1);
    require(b, errorMessage2);
  }

  ///@dev Requires the three conditions to be true 
  function assertEqual(bool condition, bool value, string memory errorMessage) internal pure {
    require(condition == value, errorMessage);
  }
  
  function assertUintGT(uint a, uint b, string memory errorMessage) internal pure {
    require(a > b, errorMessage);
  }

  ///@dev Requires either of the conditions to be true 
  function assertEither(bool a, bool b, string memory errorMessage) internal pure {
    require(a || b, errorMessage);
  }

  function getAndCompareAllowance(address token, address owner, address beneficiary, uint comparedTo) internal view returns(uint allowance) {
    allowance = IERC20Extended(token).allowance(owner, beneficiary);
    require(allowance >= comparedTo, "Allowance value is too low");
    return allowance;
  }

  function transferToken(address token, address to, uint amount) internal {
    require(IERC20Extended(token).transfer(to, amount), 'Failed');
  }

  function transferAllowance(uint amount, address token, address owner, address recipient) internal returns(uint) {
    require(IERC20Extended(token).transferFrom(owner, recipient, amount), "Operation failed");
    return amount;
  }

  function calculateReward(uint stakedAmt, uint depositTime, uint divisor) internal view returns(uint reward) {
    uint curTime = block.timestamp;
    if(curTime == depositTime) {
      reward = 10 ** 15;
      return reward;
    }

    if(curTime > depositTime) {
        uint timeDiff = curTime.sub(depositTime);
        if(timeDiff > 0){
            reward = timeDiff.mul(stakedAmt).div(divisor); // Weighted reward
        } else {
            reward = 1e15;
        }

    }
    return reward;
  }

  /// Mint rewardToken to staker on staking receipt
  function mintRewardToken(address to, address token, uint amount) internal {
    require(IERC20Extended(token).mint(to, amount), "Error minting");
  }
  
  
}