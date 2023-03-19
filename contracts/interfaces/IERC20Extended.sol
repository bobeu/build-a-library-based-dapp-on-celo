// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../reward/IERC20.sol";

interface IERC20Extended is IERC20 {
  function mint(address to, uint amount) external returns(bool);
}