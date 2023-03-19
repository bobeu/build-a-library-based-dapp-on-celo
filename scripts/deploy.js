import { ethers } from "hardhat";
import Web3 from 'web3'

async function main() {
  const minimumStake = Web3.utils.toHex('100000000000000000');
  const maxStake = Web3.utils.toHex('500000000000000000000000000');
  const VaultLib = await ethers.getContractFactory("VaultLib");
  const vaultLib = await VaultLib.deploy();

  const Vault = await ethers.getContractFactory("Vault", {
    libraries: {
      VaultLib: vaultLib.address,
    }
  });
  const RewardToken = await ethers.getContractFactory("RewardToken");

  const vault = await Vault.deploy(minimumStake);
  const token = await RewardToken.deploy(vault.address, maxStake);

  await vault.deployed();
  await token.deployed();

  console.log(`Vault depoyed to ${vault.address}`);
  console.log(`Token depoyed to ${token.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
