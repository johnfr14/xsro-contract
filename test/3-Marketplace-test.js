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
  describe('createSale', function () {
    it('Should create a sale', async function () {
      await marketplace.connect(alice).createSale(nft.address, 1, ethers.utils.parseEther('10'));
      expect(await marketplace.totalSale()).to.be.equal(1);
    });
    it('Should list the order', async function () {
      await marketplace.connect(alice).createSale(nft.address, 1, ethers.utils.parseEther('10'));
      tx = await marketplace.getSale(1);
      expect(tx[3]).to.be.equal(alice.address);
    });
    it('Should emit an event', async function () {
      tx = marketplace.connect(alice).createSale(nft.address, 1, ethers.utils.parseEther('10'));
      await expect(tx).to.emit(marketplace, 'Registered').withArgs(alice.address, 1);
    });
    it('Should revert with not a contract', async function () {
      await expect(marketplace.createSale(bob.address, 1, 100)).to.be.revertedWith(
        'Marketplace: collection address is not a contract'
      );
    });
    it('Should revert if not owner of the nft', async function () {
      await expect(marketplace.createSale(nft.address, 1, ethers.utils.parseEther('10'))).to.be.revertedWith(
        'Markerplace: you must be the owner of this nft'
      );
    });
    it('Should revert if marketplace is not approve', async function () {
      await nft.connect(bob).create(20, 'Second', 'The second nft', 'https://sarahro.io/');
      await expect(marketplace.connect(bob).createSale(nft.address, 2, 1)).to.be.revertedWith(
        'Marketplace: you need to approve this contract'
      );
    });
  });
  describe('setPrice', function () {
    beforeEach(async function () {
      await marketplace.connect(alice).createSale(nft.address, 1, ethers.utils.parseEther('10'));
    });
    it('Should change price', async function () {
      await marketplace.connect(alice).setPrice(1, ethers.utils.parseEther('20'));
      tx = await marketplace.getSale(1);
      await expect(tx.price).to.be.equal(ethers.utils.parseEther('20'));
    });
    it('Should emit an event', async function () {
      tx = marketplace.connect(alice).setPrice(1, ethers.utils.parseEther('20'));
      await expect(tx).to.emit(marketplace, 'PriceChanged').withArgs(1, ethers.utils.parseEther('20'));
    });
    it('Should revert if nft is not on sale', async function () {
      await expect(marketplace.setPrice(2, 2)).to.be.revertedWith('Marketplace: this nft is not on sale');
    });
    it('Should revert if not nft owner', async function () {
      await expect(marketplace.setPrice(1, 2)).to.be.revertedWith('Markerplace: you must be the seller of this nft');
    });
  });
  describe('removeSale', function () {
    beforeEach(async function () {
      await marketplace.connect(alice).createSale(nft.address, 1, ethers.utils.parseEther('10'));
    });
    it('Should remove the sale', async function () {
      await marketplace.connect(alice).removeSale(1);
      expect(await marketplace.isOnSale(nft.address, 1)).to.be.false;
    });
    it('Should emit an event', async function () {
      tx = marketplace.connect(alice).removeSale(1);
      await expect(tx).to.emit(marketplace, 'Cancelled').withArgs(alice.address, 1);
    });
    it('Should revert if nft is not on sale', async function () {
      await expect(marketplace.removeSale(2)).to.be.revertedWith('Marketplace: this nft is not on sale');
    });
    it('Should revert if not nft owner', async function () {
      await expect(marketplace.removeSale(1)).to.be.revertedWith('Markerplace: you must be the seller of this nft');
    });
  });
  describe('buyNft', function () {
    beforeEach(async function () {
      await marketplace.connect(alice).createSale(nft.address, 1, ethers.utils.parseEther('10'));
      await xsro.approve(marketplace.address, ethers.utils.parseEther('10'));
      await marketplace.buyNft(1);
    });
    it('Should transfer the nft to the buyer', async function () {
      expect(await nft.balanceOf(deployer.address)).to.be.equal(1);
    });
    it('Should transfer the erc20 to the seller', async function () {
      expect(await xsro.balanceOf(alice.address)).to.be.equal(ethers.utils.parseEther('10'));
    });
    it('Should emit an event', async function () {
      await nft.approve(marketplace.address, 1);
      await marketplace.createSale(nft.address, 1, ethers.utils.parseEther('10'));
      await xsro.connect(alice).approve(marketplace.address, ethers.utils.parseEther('10'));
      tx = marketplace.connect(alice).buyNft(2);
      await expect(tx).to.emit(marketplace, 'Sold').withArgs(alice.address, 2);
    });
    it('Should revert if nft is not on sale', async function () {
      await expect(marketplace.buyNft(3)).to.be.revertedWith('Marketplace: this nft is not on sale');
    });
    it("Should revert if buyer don't have enough xSRO", async function () {
      await nft.approve(marketplace.address, 1);
      await marketplace.createSale(nft.address, 1, ethers.utils.parseEther('10'));
      await xsro.connect(bob).approve(marketplace.address, ethers.utils.parseEther('10'));
      await expect(marketplace.connect(bob).buyNft(2)).to.be.revertedWith('Marketplace: not enough xSRO');
    });
    it('Should revert if buyer allowance is not enough', async function () {
      await nft.approve(marketplace.address, 1);
      await marketplace.createSale(nft.address, 1, ethers.utils.parseEther('10'));
      await expect(marketplace.connect(alice).buyNft(2)).to.be.revertedWith(
        'Marketplace: you need to approve this contract to buy'
      );
    });
  });
  describe('getSale', function () {
    beforeEach(async function () {
      await marketplace.connect(alice).createSale(nft.address, 1, ethers.utils.parseEther('10'));
      tx = await marketplace.getSale(1);
    });
    it('Status', async function () {
      expect(tx.status).to.be.equal(1);
    });
    it('NftId', async function () {
      expect(tx.nftId).to.be.equal(1);
    });
    it('Price', async function () {
      expect(tx.price).to.be.equal(ethers.utils.parseEther('10'));
    });
    it('Seller', async function () {
      expect(tx.seller).to.be.equal(alice.address);
    });
    it('Collection', async function () {
      expect(tx.collection).to.be.equal(nft.address);
    });
  });
  describe('getSaleId', function () {
    beforeEach(async function () {
      await marketplace.connect(alice).createSale(nft.address, 1, ethers.utils.parseEther('10'));
    });
    it('Should return the sale id', async function () {
      expect(await marketplace.getSaleId(nft.address, 1)).to.be.equal(1);
    });
    it('Should return 0 if nft is sold', async function () {
      await xsro.approve(marketplace.address, ethers.utils.parseEther('10'));
      await marketplace.buyNft(1);
      expect(await marketplace.getSaleId(nft.address, 1)).to.be.equal(0);
    });
    it('Should return 0 if the sale is cancelled', async function () {
      await marketplace.connect(alice).removeSale(1);
      expect(await marketplace.getSaleId(nft.address, 1)).to.be.equal(0);
    });
  });
  describe('isOnSale', function () {
    beforeEach(async function () {
      await marketplace.connect(alice).createSale(nft.address, 1, ethers.utils.parseEther('10'));
    });
    it('Should return true if nft is on sale', async function () {
      expect(await marketplace.isOnSale(nft.address, 1)).to.be.true;
    });
    it('Should return false if not on sale', async function () {
      expect(await marketplace.isOnSale(nft.address, 2)).to.be.false;
    });
    it('Should return false if nft is sold', async function () {
      await xsro.approve(marketplace.address, ethers.utils.parseEther('10'));
      await marketplace.buyNft(1);
      expect(await marketplace.isOnSale(nft.address, 1)).to.be.false;
    });
    it('Should return false if the sale is cancelled', async function () {
      await marketplace.connect(alice).removeSale(1);
      expect(await marketplace.isOnSale(nft.address, 1)).to.be.false;
    });
  });
  describe('totalSale', function () {
    beforeEach(async function () {
      await marketplace.connect(alice).createSale(nft.address, 1, ethers.utils.parseEther('10'));
    });
    it('Should return the total sale created', async function () {
      expect(await marketplace.totalSale()).to.be.equal(1);
    });
  });
});
