const { BN, ether, constants, expectEvent, shouldFail, time } = require('@openzeppelin/test-helpers');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');

const MockERC721 = artifacts.require('MockERC721');

contract('Test token', ([creator, ...accounts]) => {
  const [owner, acc1, acc2, acc3] = accounts;

  describe('Ale Edition', () => {
    var token;

    beforeEach(async () => {
      token = await MockERC721.new('Ale-token', 'ALE', {from: owner});
    })


    it('allow users', async () => {
      await token.addPresaleMembers([{user: acc1, maxCount: 2}, {user: acc2, maxCount: 3}, {user: acc3, maxCount: 4}], {from: owner})

      let acc1Count = await token.getAllowedUserCount(acc1);
      let acc2Count = await token.getAllowedUserCount(acc2);
      let acc3Count = await token.getAllowedUserCount(acc3);

      assert.equal(acc1Count, 2);
      assert.equal(acc2Count, 3);
      assert.equal(acc3Count, 4);

    })

    it('allow users, sale activation and presale mint', async () => {
      // allow users
      await token.addPresaleMembers([{user: acc1, maxCount: 4}], {from: owner});

      // sale activation
      await token.setPrivateSaleActive({from: owner});

      // time travel
      await time.increaseTo((await time.latest()).add(time.duration.hours(1)));

      await token.privateMint(acc1, 4, {from: acc1, value: web3.utils.toWei("0.2", "ether")})

      // time travel
      await time.increaseTo((await time.latest()).add(time.duration.hours(24)));

      // public mint
      await token.publicMint(acc2, 100, {from: acc2, value: web3.utils.toWei("5", "ether")})
    })
  })
})