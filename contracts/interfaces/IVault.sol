// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVault {
  error TokenAlreadySupported(address);
  error NoStakingDetected(uint);
  error InvalidStakeId(uint);
  error NothingToUnstake();
  error ZeroValue(uint);
  error NotAuthorized();

  struct Staker {
    uint depositTime;
    uint stake;
    uint celoAmount;
    address account;
  }

  struct Paired {
    uint index;
    bool isPaired;
  }

  struct Pair {
    address tokenA;
    address tokenB;
    uint rate;
    uint minimumStake;
    uint liquidity;
    bool isOpen;
  }

  function stake() external payable returns(bool);
  function unstake() external returns(bool);
  function stakeOnBehalf(address who) external payable returns(bool);
}