const { accounts, contract, web3 } = require("@openzeppelin/test-environment");
const { expect } = require("chai");
const { BigNumber } = require("bignumber.js");

const [deployer, userMinter, userBuyer, userBuyer2] = accounts;

const MyNFTContract = contract.fromArtifact("NFT");

describe("NFT", function () {
  beforeEach(async function () {
    this.contract = await MyNFTContract.new({ from: deployer });
  });

  it("Mint 2 new nfts and check updated balances", async function () {
    const mintResult = await this.contract.mint(
      "URI_X",
      userMinter,
      web3.utils.toWei("12", "ether"),
      { from: userMinter }
    );
    let newTokenID = mintResult.logs[0].args.tokenId.toNumber();
    expect(newTokenID).to.eq(1);
  });
});
