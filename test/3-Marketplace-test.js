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

    await nft.connect(alice).create(20, 'First', 'The first nft', 'https://sarahro.io/');
    await nft.connect(alice).approve(marketplace.address, 1);
  });
  describe('Deployment', function () {
    it('Should set the xSRO address', async function () {
      expect(await marketplace.token()).to.be.equal(xsro.address);
    });
  });
  describe('Create sale', function () {
    it('Should create a sale', async function () {
      await marketplace.connect(alice).createSale(nft.address, 1, ethers.utils.parseEther('10'));
      expect(await marketplace.totalSale()).to.be.equal(1);
    });
    it('Should list the order', async function () {
      await marketplace.connect(alice).createSale(nft.address, 1, ethers.utils.parseEther('10'));
      tx = await marketplace.getSale(1);
      expect(tx[3]).to.be.equal(alice.address);
    });
    it('Should revert with not a contract', async function () {
      await expect(marketplace.createSale(bob.address, 1, 100)).to.be.revertedWith(
        'Marketplace: collection address is not a contract'
      );
    });
    it('Should ');
  });
});
