import { expect } from "chai";
import { ethers } from "hardhat";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";
import { BtcTxParserMock } from "@/generated-types/ethers";
import { BtcTxParser } from "@/generated-types/ethers/contracts/mock/libs/bitcoin/BtcTxParserMock";

function showParsedTx(tx: BtcTxParser.TransactionStructOutput) {
  console.log("version:", tx.version);
  console.log("inputs:", tx.inputs);
  console.log("outputs:", tx.outputs);
  console.log("locktime:", tx.locktime);
  console.log("hasWitness:", tx.hasWitness);
}

describe("BTC Transaction Parser", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;

  let btc: BtcTxParserMock;

  before(async () => {
    [OWNER] = await ethers.getSigners();

    const BtcTxParserMock = await ethers.getContractFactory("BtcTxParserMock");
    btc = await BtcTxParserMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("#parse", () => {
    it("should parse correctly", async () => {
      let tx = await btc.parseBTCTransaction(
        "0x01000000000101cf337081287de9b93bb8ea17fbaf80e38f24389ab1f5b5519394741e1d91d34d0200000000ffffffff04c7e70800000000001976a914c250b1198b5770a2d00365f0b1660906ddc459e488ac524504000000000017a914c7f0b23c10270adefbe5d2c07b91c281172ca910874cc10100000000001600144d0e22355a0a85c735cd1292ce25dae949f4b538bbd9ea0200000000160014af6aa4350ca438793fa8fc965661df5e4b311640024730440220749a385c9fc2d32728ac4c0ac338ef1ec74a279f8c49677b745e0e6ee55aadad02202f0b7f72980cca5992bfd47a872592cb23bf23cf801e5403f688648feda44f77012103cbb1ede1735af832852b78ebbe9afaf38d233fbaeffe1d90dfb87bbd5a70e14300000000",
      );

      showParsedTx(tx);

      expect(tx.version).to.be.eq(1);
      expect(tx.hasWitness).to.be.true;

      tx = await btc.parseBTCTransaction(
        "0x0200000001273ad5266d581ad7d22d7292d63646884da6b2e057655ca5e5ef3bb725539385010000006b483045022100feb480f5d8a8db40fc7584d0f66bcc1234f8d153d935aca854b2ae9fd12075100220712b5d66eacd9784e7464c3c86182d1c82cdfce66f83f8390fbf88a9a3d44d600121038a460a2d12fabe8b0b6a4252cee64984720e7bde699cd3099c741d7b04de4eb9fdffffff01effa4300000000001976a9145e44821c5abd14e2162bc25449ff9835a5ba388288ac00000000",
      );

      showParsedTx(tx);

      expect(tx.version).to.be.eq(2);
      expect(tx.hasWitness).to.be.not.true;
    });

    it("should revert", async () => {
      const invalidVersionTx =
        "0x03000000000101cf337081287de9b93bb8ea17fbaf80e38f24389ab1f5b5519394741e1d91d34d0200000000ffffffff04c7e70800000000001976a914c250b1198b5770a2d00365f0b1660906ddc459e488ac524504000000000017a914c7f0b23c10270adefbe5d2c07b91c281172ca910874cc10100000000001600144d0e22355a0a85c735cd1292ce25dae949f4b538bbd9ea0200000000160014af6aa4350ca438793fa8fc965661df5e4b311640024730440220749a385c9fc2d32728ac4c0ac338ef1ec74a279f8c49677b745e0e6ee55aadad02202f0b7f72980cca5992bfd47a872592cb23bf23cf801e5403f688648feda44f77012103cbb1ede1735af832852b78ebbe9afaf38d233fbaeffe1d90dfb87bbd5a70e14300000000";
      const invalidFlagTx =
        "0x02000000000201cf251026b2625d4b4ddd8f94dba9205ae963e757177972e5a0a36b446283c1090200000000fdffffff02e6c9010000000000160014b201b5368f2a65048b72f0b4ca3845b1c299a26e0000000000000000116a5d0eff7f818cec82d08bc0a88281d21502483045022100ca4f0302f7e22e589918fe13cb61367baf1b6f4c23b5bae55ba508dc8657243202204d5f7dc80d126f7c35440a6ea5718938bcf7cb8c9307a06d6f1f585c38fbd7c4012103a46fa6d023dddc643cfb5a26753dabf1f6bdf366f3d5f101cf01abe9ffb70bb600000000";
      const shortFlagTx = "0x0200000000";
      const shortTx = "0x01000000";

      await expect(btc.parseBTCTransaction(invalidVersionTx))
        .to.be.revertedWithCustomError(btc, "UnsupportedVersion")
        .withArgs(3);

      await expect(btc.parseBTCTransaction(invalidFlagTx))
        .to.be.revertedWithCustomError(btc, "InvalidFlag")
        .withArgs(2);

      await expect(btc.parseBTCTransaction(shortFlagTx)).to.be.revertedWithCustomError(btc, "InvalidFlag").withArgs(0);

      await expect(btc.parseBTCTransaction(shortTx)).to.be.revertedWithCustomError(btc, "BufferOverflow");
    });
  });

  describe("#format", () => {
    it("formatTransactionInput", async () => {
      let originalInput0 = "0xac25a2dde5cae58b8f486495fcb91833767dc6fcc41e29dde07a26e3bdd892314100000000fdffffff";
      let tx = await btc.parseBTCTransaction(
        "0x01000000000101ac25a2dde5cae58b8f486495fcb91833767dc6fcc41e29dde07a26e3bdd892314100000000fdffffff026504000000000000160014806a28235d319ec80b2d6a32d725381acabd347b0000000000000000116a5d0eff7f818cec82d08bc0a88281d2150140240b847cd78c8803cee41f708e154345ba07adde2af6e2fdc66453678d681b76a2a499a37b5ab3e4414c1360fc0552206350744eeeea4b1e9c35f8f08bdc3b8900000000",
      );

      let input0Parsed = {
        previousHash: tx.inputs[0].previousHash,
        previousIndex: tx.inputs[0].previousIndex,
        sequence: tx.inputs[0].sequence,
        script: tx.inputs[0].script,
        witnesses: [...tx.inputs[0].witnesses],
      };

      expect(await btc.formatTransactionInput(input0Parsed)).to.be.eq(originalInput0);

      const txWithScript =
        "0x02000000072a36b8c4bea06fa980f11774a9db8c50911ab263382a7920123266e07e7dea1a000000006a47304402202c1caf8fa24dd1818fb423502c1ac00a1320ef30c2f9a3e0f987c8dd5865056f02206628632d51b3adcf1c94284a853ec853e1c6ca27864106b3611612b34636175c012103581ea6d3b0666ce712ff7697043a0085e4fc52e10fe819b32b6f7bec5c10164ffdffffff0e94ad3b3623e22b9e7c520f587f19636d978eaf42f2547c914f294202c81655010000006a47304402200b667ef3b76f5ad125fafe732857305f64d19ba9557764afb4ccdb38848de40602207f285a5270cc259cd3140c9b923967f7ab985fa412de6395aec4b6e214b4946e01210356dc58d43a2d2558832c97ce8b2dedfee42aa64a7b2ad279a3738f5d4b9abb7bfdffffffc4bc9a85db21efd8b5c9fae9c4dccd57e7ba79e1110fa5dde32e99e870543156000000006a47304402207a82f741e40510e229c7c76f8cc39e669c3f4381ab58b5abe02d355ecbde3d2802205675a6a23bd601f9d6ca9d1ca22b317985de6e99e14991b9ade44331404d00b5012103ae0db296ccb9b4b9bec08874ac452845777f77cc9d0f5cd77cc70d9db20bd031fdffffff8ac8f75df1a18e87c3589b2c7095f2e4935c7acfc28f53a565d799744771296f000000006a4730440220206887979f1b1af6168e6cbdb6185bf21a140e3d30c69abbaf470251baf58d2d0220683366a718b5436b74ff2366c3919b8359bea32e3b3ec9d0d54b8ae3c758da86012103ac68ec6bffa573aef22873989b0a703adf73b44c02097885e1afb53f463a3ad8fdffffffc8c380d96f52e37aa2582b4c7856abf402e18be753c7e35f6178cebf5fa8b793000000006a473044022063843a0fb2420c37d14d4741be1da0f709998031cf071f4991a6cba7c6f3283a02202d159254cadfda23bb8d35d77212c9dba139dee7ce351fda0878ed5e4b950d55012103e1d81aced6558aecc226720d8e83b0eba3903f7db4223c12024731ee0432c18cfdffffff12ef772edcf67f70c26818840bf22a03d9fd0bc3eaaef0d4b5094b52508de793000000006a473044022076c8ad98446684787a6d4936c7ce06e7c0ea888cf6cb6c978960e73baae2450202200695b30aa8399d479bbf10d45e5a117108ae37fc71289f88e8d5c9ee6ca9081c012102b8bf904223d8c222e7482f6c8634d907147743ad79b38d48aaf60758c6cc9715fdffffff1296f9db6929240f4b2ed97f8a5bce3516ad6d2174696361e908aef1168abccb000000006a4730440220732346d671f9b37277cea31442746e12caba6edf60293a2ff3a754d58c201969022042c3a98ce1da779d821cdc332d1077305ff33ef4d24b51a198949bbf2cb67d29012103581ea6d3b0666ce712ff7697043a0085e4fc52e10fe819b32b6f7bec5c10164ffdffffff02cc880500000000001976a914f5f0fff638ce7ecaa94b8d728ea3506e7e598edd88ac78a99c000000000016001424cf6cc7b9b17d3a65ce1d2528ce4e7c7db2059bdbc80d00";
      originalInput0 =
        "0x2a36b8c4bea06fa980f11774a9db8c50911ab263382a7920123266e07e7dea1a000000006a47304402202c1caf8fa24dd1818fb423502c1ac00a1320ef30c2f9a3e0f987c8dd5865056f02206628632d51b3adcf1c94284a853ec853e1c6ca27864106b3611612b34636175c012103581ea6d3b0666ce712ff7697043a0085e4fc52e10fe819b32b6f7bec5c10164ffdffffff";

      tx = await btc.parseBTCTransaction(txWithScript);

      input0Parsed = {
        previousHash: tx.inputs[0].previousHash,
        previousIndex: tx.inputs[0].previousIndex,
        sequence: tx.inputs[0].sequence,
        script: tx.inputs[0].script,
        witnesses: [...tx.inputs[0].witnesses],
      };

      expect(await btc.formatTransactionInput(input0Parsed)).to.be.eq(originalInput0);
    });

    it("formatTransactionOutput", async () => {
      const originalOutput0 = "0x6504000000000000160014806a28235d319ec80b2d6a32d725381acabd347b";
      const originalOutput1 = "0x0000000000000000116a5d0eff7f818cec82d08bc0a88281d215";

      const tx = await btc.parseBTCTransaction(
        "0x01000000000101ac25a2dde5cae58b8f486495fcb91833767dc6fcc41e29dde07a26e3bdd892314100000000fdffffff026504000000000000160014806a28235d319ec80b2d6a32d725381acabd347b0000000000000000116a5d0eff7f818cec82d08bc0a88281d2150140240b847cd78c8803cee41f708e154345ba07adde2af6e2fdc66453678d681b76a2a499a37b5ab3e4414c1360fc0552206350744eeeea4b1e9c35f8f08bdc3b8900000000",
      );

      const output0Parsed = {
        value: tx.outputs[0].value,
        script: tx.outputs[0].script,
      };

      const output1Parsed = {
        value: tx.outputs[1].value,
        script: tx.outputs[1].script,
      };

      expect(await btc.formatTransactionOutput(output0Parsed)).to.be.eq(originalOutput0);
      expect(await btc.formatTransactionOutput(output1Parsed)).to.be.eq(originalOutput1);
    });
  });

  describe("#parseCuint", () => {
    it("should parse correctly", async () => {
      const cuint = "0x03";

      let parsed = await btc.parseCuint(cuint, 0);
      expect(parsed).to.be.deep.eq([3, 1]);

      const cuint2 = "0xfd0001";

      parsed = await btc.parseCuint(cuint2, 0);
      expect(parsed).to.be.deep.eq([256, 3]);

      const cuint3 = "0xfe01000000";

      parsed = await btc.parseCuint(cuint3, 0);
      expect(parsed).to.be.deep.eq([1, 5]);

      const cuint4 = "0xff0010000000000000";

      parsed = await btc.parseCuint(cuint4, 0);
      expect(parsed).to.be.deep.eq([4096, 9]);
    });
  });
});
