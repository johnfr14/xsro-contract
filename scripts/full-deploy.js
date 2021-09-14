const hre = require('hardhat');
const { deployed } = require('./deployed');

const TOKEN_CONTRACT = 'xSRO';
const NFT_CONTRACT = 'SRO721';
const MARKETPLACE_CONTRACT = 'Marketplace';
const SWAP_CONTRACT = 'SwapSRO';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying ${TOKEN_CONTRACT} with the account:`, deployer.address);

  const xSRO = await hre.ethers.getContractFactory('SarahRO');
  const xsro = await xSRO.deploy();

  await xsro.deployed();

  await deployed(TOKEN_CONTRACT, hre.network.name, xsro.address);

  // MARKETPLACE
  console.log(`Deploying ${MARKETPLACE_CONTRACT} with the account:`, deployer.address);

  const MARKETPLACE = await hre.ethers.getContractFactory('Marketplace');
  const marketplace = await MARKETPLACE.deploy(xsro.address);

  await marketplace.deployed();

  await deployed(MARKETPLACE_CONTRACT, hre.network.name, marketplace.address);

  // NFT
  console.log(`Deploying ${NFT_CONTRACT} with the account:`, deployer.address);

  const NFT = await hre.ethers.getContractFactory('SRO721');
  const nft = await NFT.deploy(marketplace.address);

  await nft.deployed();

  await deployed(NFT_CONTRACT, hre.network.name, nft.address);

  // SwapSRO
  console.log(`Deploying ${SWAP_CONTRACT} with the account:`, deployer.address);

  const SWAP = await hre.ethers.getContractFactory('SwapSRO');
  const swap = await SWAP.deploy(xsro.address, deployer.address);

  await swap.deployed();

  await deployed(SWAP_CONTRACT, hre.network.name, swap.address);

  // Owner approve token
  console.log(`Approve ${SWAP_CONTRACT} from ${TOKEN_CONTRACT} with the account:`, deployer.address);

  await xsro.approve(swap.address, ethers.utils.parseEther('10000000'));
  console.log(`${TOKEN_CONTRACT}: ${swap.address} has been approved by ${deployer.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
