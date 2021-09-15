/* eslint-disable quotes */
/* eslint-disable no-undef */

const { expect } = require('chai');

describe('SRO721', function () {
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
    it('Should have name ERC721', async function () {
      expect(await nft.name()).to.be.equal('ERC721');
    });
    it('Should have symbol 721', async function () {
      expect(await nft.symbol()).to.be.equal('721');
    });
    it('Should set the marketplace address', async function () {
      expect(await nft.marketAddress()).to.be.equal(marketplace.address);
    });
  });
  // function Create
  describe('Create', function () {
    beforeEach(async function () {
      tx = nft.connect(alice).create(20, 'First', 'The first nft', 'https://sarahro.io/');
    });
    it('Should mint a nft', async function () {
      await expect(() => tx).to.changeTokenBalance(nft, alice, 1);
    });
    it('Should emit an event', async function () {
      await expect(tx).to.emit(nft, 'Created').withArgs(alice.address, 1);
    });
    it('Should revert if royalties is over 50%', async function () {
      await expect(nft.create(51, 'Revert', '', '')).to.revertedWith('SRO721: royalties max amount is 50%');
    });
  });
  // Function Like
  describe('Like', function () {
    beforeEach(async function () {
      await nft.connect(alice).create(20, 'First', 'The first nft', 'https://sarahro.io/');
    });
    it('Should like the nft', async function () {
      await nft.connect(bob).like(1);
      expect(await nft.isLiked(bob.address, 1)).to.be.true;
    });
    it('Should remove the like from the nft', async function () {
      await nft.connect(bob).like(1);
      await nft.connect(bob).like(1);
      expect(await nft.isLiked(bob.address, 1)).to.be.false;
    });
    it('Should increase the like on the nft', async function () {
      await nft.connect(bob).like(1);
      await nft.connect(alice).like(1);
      tx = await nft.getNftById(1);
      expect(tx.likes).to.be.equal(2);
    });
    it('Should emit an event', async function () {
      await expect(nft.connect(bob).like(1)).to.emit(nft, 'Liked').withArgs(bob.address, 1, true);
    });
    it('Should revert if id equal 0', async function () {
      await expect(nft.like(0)).to.be.revertedWith('SRO721: Out of bounds');
    });
    it('Should revert if id is superior to the total supply', async function () {
      await expect(nft.like(2)).to.be.revertedWith('SRO721: Out of bounds');
    });
  });
  describe('Transfer', function () {
    beforeEach(async function () {
      await nft.connect(alice).create(20, 'First', 'The first nft', 'https://sarahro.io/');
    });
    it('Should transfer to bob', async function () {
      await nft.connect(alice)['safeTransferFrom(address,address,uint256)'](alice.address, bob.address, 1);
      expect(await nft.ownerOf(1)).to.be.equal(bob.address);
    });
    it('Should fail while nft is on sale on the marketplace', async function () {
      await nft.connect(alice).approve(marketplace.address, 1);
      await marketplace.connect(alice).createSale(nft.address, 1, 1);
      await expect(
        nft.connect(alice)['safeTransferFrom(address,address,uint256)'](alice.address, bob.address, 1)
      ).to.be.revertedWith('SRO721: you cannot transfer your nft while it is on sale');
    });
    it('Should transfer if nft is remove from the marketplace', async function () {
      await nft.connect(alice).approve(marketplace.address, 1);
      await marketplace.connect(alice).createSale(nft.address, 1, 1);
      await marketplace.connect(alice).removeSale(1);
      await nft.connect(alice)['safeTransferFrom(address,address,uint256)'](alice.address, bob.address, 1);
      expect(await nft.ownerOf(1)).to.be.equal(bob.address);
    });
  });
  // Function getNftById / tokenURI
  describe('GetNftById and tokenURI', function () {
    beforeEach(async function () {
      await nft.connect(alice).create(20, 'First', 'The first nft', 'https://sarahro.io/');
      await nft.connect(bob).like(1);
      tx = await nft.getNftById(1);
    });
    it('Title', async function () {
      expect(tx.title).to.be.equal('First');
    });
    it('Description', async function () {
      expect(tx.description).to.be.equal('The first nft');
    });
    it('Author', async function () {
      expect(tx.author).to.be.equal(alice.address);
    });
    it('Royalties', async function () {
      expect(tx.royalties).to.be.equal(20);
    });
    it('Likes', async function () {
      expect(tx.likes).to.be.equal(1);
    });
    // innacurate method
    it('Timestamp', async function () {
      await ethers.provider.send('evm_setNextBlockTimestamp', [1672527600]); // 01/01/23 00:00:00 GMT +0100
      await ethers.provider.send('evm_mine');
      await nft.connect(alice).create(50, 'Second', 'The second nft', 'https://sarahro.io/');
      tx = await nft.getNftById(2);
      expect(tx.timestamp).to.be.equal(1672527601);
    });
    it('URI', async function () {
      expect(await nft.tokenURI(1)).to.be.equal('https://sarahro.io/');
    });
  });
  describe('GetNftByAuthor', function () {
    beforeEach(async function () {
      await nft.connect(alice).create(10, 'First', 'The first nft', 'https://sarahro.io/');
      await nft.connect(bob).create(20, 'Second', 'The second nft', 'https://sarahro.io/');
      await nft.connect(alice).create(30, 'Third', 'The third nft', 'https://sarahro.io/');
    });
    describe('NFT Author: Alice', function () {
      it('Total', async function () {
        expect(await nft.getNftByAuthorTotal(alice.address)).to.be.equal(2);
      });
      it('NFT 1', async function () {
        expect(await nft.getNftByAuthorAt(alice.address, 0)).to.be.equal(1);
      });
      it('NFT 2', async function () {
        expect(await nft.getNftByAuthorAt(alice.address, 1)).to.be.equal(3);
      });
    });
    describe('NFT Author: Bob', function () {
      it('Total', async function () {
        expect(await nft.getNftByAuthorTotal(bob.address)).to.be.equal(1);
      });
      it('NFT 1', async function () {
        expect(await nft.getNftByAuthorAt(bob.address, 0)).to.be.equal(2);
      });
    });
  });
});
