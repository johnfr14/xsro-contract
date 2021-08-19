/* eslint-disable quotes */
/* eslint-disable no-undef */

const { expect } = require('chai');

describe('xSRO', function () {
  it('Should return the xSRO value', async function () {
    const xSRO = await ethers.getContractFactory('SarahRO');
    const xsro = await xSRO.deploy();

    await xsro.deployed();
    expect(await xsro.name()).to.equal('xSarahRO');
    expect(await xsro.symbol()).to.equal('xSRO');
  });
});
