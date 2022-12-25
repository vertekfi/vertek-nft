import { ethers } from "hardhat";

async function deployFactory() {
  const contractName = ''
  const SmartChefFactory = await ethers.getContractFactory(contractName);
  const factory = await SmartChefFactory.deploy();
  await factory.deployed();

  console.log(`${contractName} deployed to ${factory.address}`);
}

async function deployPool() {}

async function main() {
  await deployFactory();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
