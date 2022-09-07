import { ethers } from "hardhat";

async function deployFactory() {
  const SmartChefFactory = await ethers.getContractFactory("SmartChefFactory");
  const factory = await SmartChefFactory.deploy();
  await factory.deployed();

  console.log(`SmartChefFactory deployed to ${factory.address}`);
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
