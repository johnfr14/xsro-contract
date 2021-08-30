/* eslint-disable space-before-function-paren */
/* eslint-disable no-undef */
const hre = require('hardhat');
const { deployed } = require('./deployed');
const { readJson } = require('./readJson');

const TOKEN_CONTRACT = 'xSRO';

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // Optionnel car l'account deployer est utilisé par défaut
  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address);

  const json = await readJson();

  // We get the contract to deploy
  const MARKETPLACE = await hre.ethers.getContractFactory('SwapSRO');
  const marketplace = await MARKETPLACE.deploy(json[TOKEN_CONTRACT][hre.network.name].address);

  // Attendre que le contrat soit réellement déployé, cad que la transaction de déploiement
  // soit incluse dans un bloc
  await marketplace.deployed();

  // Create/update deployed.json and print usefull information on the console.
  await deployed('Marketplace', hre.network.name, marketplace.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
