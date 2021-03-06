/* eslint-disable quotes */
/* eslint-disable no-undef */

const { expect } = require('chai');

describe('Swap', function () {
  let deployer, alice, xSRO, xsro, SWAP, swap, tx;

  beforeEach(async function () {
    [deployer, alice, bob] = await ethers.getSigners();
    xSRO = await ethers.getContractFactory('SarahRO');
    xsro = await xSRO.connect(deployer).deploy();

    await xsro.deployed();

    SWAP = await ethers.getContractFactory('SwapSRO');
    swap = await SWAP.connect(deployer).deploy(xsro.address, deployer.address);

    await swap.deployed();

    await xsro.approve(swap.address, ethers.utils.parseEther('1000000'));
  });
  describe('Deployment', function () {
    it('Token address', async function () {
      expect(await swap.token()).to.be.equal(xsro.address);
    });
    it('Token owner address', async function () {
      expect(await swap.tokenOwner()).to.be.equal(deployer.address);
    });
    it('Rate', async function () {
      expect(await swap.rate()).to.be.equal(1000);
    });
  });
  describe('Swap ETH to xSRO', function () {
    it('Should transfer xSRO from deployer to buyer', async function () {
      tx = alice.sendTransaction({ to: swap.address, value: ethers.utils.parseEther('1') });
      await expect(() => tx).to.changeTokenBalances(
        xsro,
        [deployer, alice],
        [ethers.utils.parseEther('1000').mul(-1), ethers.utils.parseEther('1000')]
      );
    });
    it('Should transfer ETH from buyer to swap contract', async function () {
      tx = await swap.connect(alice).swapTokens({ value: ethers.utils.parseEther('2') });
      expect(tx).to.changeEtherBalances(
        [swap, alice],
        [ethers.utils.parseEther('2'), ethers.utils.parseEther('2').mul(-1)]
      );
    });
    it('Should emit an event', async function () {
      await expect(swap.connect(alice).swapTokens({ value: ethers.utils.parseEther('5') }))
        .to.emit(swap, 'Swapped')
        .withArgs(alice.address, ethers.utils.parseEther('5'), ethers.utils.parseEther('5000'));
    });
    it('Should revert if the allowance from token owner is not enough', async function () {
      await xsro.approve(swap.address, ethers.utils.parseEther('1'));
      await expect(swap.connect(alice).swapTokens({ value: ethers.utils.parseEther('2') })).to.be.revertedWith(
        'SwapSRO: you cannot swap more than the allowance'
      );
    });
  });
  describe('withdrawAll', function () {
    beforeEach(async function () {
      await swap.connect(alice).swapTokens({ value: ethers.utils.parseEther('2') });
    });
    it('Should transfer ETH from swap to owner', async function () {
      expect(await swap.withdrawAll()).to.changeEtherBalances(
        [swap, deployer],
        [ethers.utils.parseEther('2').mul(-1), ethers.utils.parseEther('2')]
      );
    });
    it('Should emit an event', async function () {
      await expect(swap.withdrawAll())
        .to.emit(swap, 'Withdrew')
        .withArgs(deployer.address, ethers.utils.parseEther('2'));
    });
    it('Should revert if not owner', async function () {
      await expect(swap.connect(alice).withdrawAll()).to.be.revertedWith('Ownable: caller is not the owner');
    });
    it('Should revert if there is no ETH on the swap balance', async function () {
      await swap.withdrawAll();
      await expect(swap.withdrawAll()).to.be.revertedWith('SwapSRO: nothing to withdraw');
    });
  });
  describe('setRate', function () {
    it('Should change the ETH to xSRO rate', async function () {
      await swap.setRate(100);
      expect(await swap.rate()).to.be.equal(100);
    });
    it('Should emit an event', async function () {
      await expect(swap.setRate(100)).to.emit(swap, 'RateChanged').withArgs(deployer.address, 100);
    });
    it('Should revert if new rate is 0', async function () {
      await expect(swap.setRate(0)).to.be.revertedWith('SwapSRO: rate cannot be 0');
    });
  });
  describe('ownerAllowance', function () {
    it('Should return the approve amount made by the owner of the total supply', async function () {
      expect(await swap.ownerAllowance()).to.be.equal(ethers.utils.parseEther('1000000'));
    });
  });
});
