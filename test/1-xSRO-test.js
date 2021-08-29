/* eslint-disable quotes */
/* eslint-disable no-undef */

const { expect } = require('chai');

describe('xSRO', function () {
  let deployer, xSRO, xsro;

  beforeEach(async function () {
    deployer = await ethers.getSigner();
    xSRO = await ethers.getContractFactory('SarahRO');
    xsro = await xSRO.connect(deployer).deploy();

    await xsro.deployed();
  });
  describe('Deployment', function () {
    it('Should have name xSarahRO', async function () {
      expect(await xsro.name()).to.be.equal('xSarahRO');
    });
    it('Should have symbol xSRO', async function () {
      expect(await xsro.symbol()).to.be.equal('xSRO');
    });
    it(`Should have total supply of 10 000 000 xSRO`, async function () {
      expect(await xsro.totalSupply()).to.be.equal(ethers.utils.parseEther('10000000'));
    });
    it('Should mint total supply to deployer', async function () {
      expect(await xsro.balanceOf(deployer.address)).to.be.equal(ethers.utils.parseEther('10000000'));
    });
  });
});
