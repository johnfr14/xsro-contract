/* eslint-disable quotes */
/* eslint-disable no-undef */

const { expect } = require('chai');

describe('Marketplace', function () {
  let deployer, alice, bob, NFT, nft, xSRO, xsro, MARKETPLACE, marketplace, tx;

  beforeEach(async function () {
    [deployer, alice, bob] = await ethers.getSigners();
    xSRO = await ethers.getContractFactory('SarahRO');
    xsro = await xSRO.connect(deployer).deploy();

    await xsro.deployed();

    MARKETPLACE = await ethers.getContractFactory('Marketplace');
    marketplace = await MARKETPLACE.connect(deployer).deploy(xsro.address);

    await marketplace.deployed();

    NFT = await ethers.getContractFactory('SRO721');
    nft = await NFT.connect(deployer).deploy(marketplace.address);

    await nft.deployed();
  });
  describe('Deployment', function () {
    it('Should set the xSRO address', async function () {
      expect(await marketplace.token()).to.be.equal(xsro.address);
    });
  });
});
