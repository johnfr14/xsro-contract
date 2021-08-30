/* eslint-disable quotes */
/* eslint-disable no-undef */

const { expect } = require('chai');

describe('Marketplace', function () {
  let deployer, alice, bob, xSRO, xsro, SWAP, swap, tx;

  beforeEach(async function () {
    [deployer, alice, bob] = await ethers.getSigners();
    xSRO = await ethers.getContractFactory('SarahRO');
    xsro = await xSRO.connect(deployer).deploy();

    await xsro.deployed();

    SWAP = await ethers.getContractFactory('SwapSRO');
    swap = await SWAP.connect(deployer).deploy(xsro.address, deployer.address);

    await swap.deployed();

    await xsro.approve(swap.address, ethers.utils.parseEther('1000'));
  });
  describe('Deployment', function () {
    it('Token address', async function () {
      expect(await swap.token()).to.be.equal(xsro.address);
    });
    it('Token owner address', async function () {
      expect(await swap.tokenOwner()).to.be.equal(deployer.address);
    });
  });
});
