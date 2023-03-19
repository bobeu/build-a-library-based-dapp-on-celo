// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/libraryAsStorage/VaultLib.sol";

contract Vault is Ownable{
    using VaultLib for StorageData;
    StorageData private data;
    
    constructor (uint _minimumStake) {
        require(_minimumStake > 0, "Minimum staking too low");
        data.minimumStake = _minimumStake;
    }

    receive() external payable {
        require(msg.value > 0, "");
    }

    function setToken(address _token) public onlyOwner {
        data.setRewardToken(_token);
    }

    function setUpTokenPair(address tokenA, address tokenB, uint8 rate, uint _minStake) public {
        data.setUpTokenPair(tokenA, tokenB, rate, _minStake);
    }

    function stakeToken(uint pairId) public {  
        data.stakeToken(pairId);
    }

    function unstakeToken(uint pairId) public {
        data.unstakeToken(pairId);
    }

    ///@dev deposit $Celo to vault
    function stakeCelo() public payable returns(bool) {
        return data.stakeCelo(msg.value);
    }

    ///@dev Stake on behalf of @param who Account to stake for
    function stakeOnBehalf(address who) public payable returns(bool) {
        return data.stakeOnBehalf(who, msg.value);
    }

    /**@dev Unstake Celo from the vault.
     */
    function unstake() public returns(bool) {
        data.unstake();
        return true;
    }

    ///@dev returns account of @param who : any valid address
    function withdraw() public {
      data.withdraw();
    }

    function setSupportedToken(address _token) public onlyOwner {
        data.setSupportedToken(_token);
    }
}
