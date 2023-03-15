import { ethers, upgrades } from 'hardhat';

async function main() {
  const name = 'Vertek Fox';
  const symbol = 'VFOX';
  const cost = '500000000000000000';
  const maxSupply = 1000;
  const maxMintAmountPerTx = 1;
  const hiddenMetadataUri = 'ipfs://bafybeied4mz3at4psihbidp3szndfdjgwnjrn2ti6coir34v634kfkfcfi/hidden.json';

  const VertekFox = await ethers.getContractFactory('VertekFox');
  const nft = await upgrades.deployProxy(VertekFox, [
    name,
    symbol,
    cost,
    maxSupply,
    maxMintAmountPerTx,
    hiddenMetadataUri,
  ]);
  await nft.deployed();

  // Admin: 0x3f73B892E3C0dBb8721419a7C789362aEFfE06E2
  // Proxy: 0xb8b332a9960c645904DE7Ce278bbF9F6F56a9C7d
  // Impl: 0xA76313C4689C1660bC551bd10432a7946438efe8
  console.log(`VertekFox deployed to: ${nft.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
