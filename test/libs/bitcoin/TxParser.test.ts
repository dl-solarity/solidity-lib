import { expect } from "chai";
import { ethers } from "hardhat";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { Reverter } from "@/test/helpers/reverter";
import { TxParserMock } from "@/generated-types/ethers";
import { TxParser } from "@/generated-types/ethers/contracts/mock/libs/bitcoin/TxParserMock";
import { parseCuint, reverseBytes } from "@/test/helpers/bytes-helper";

function showParsedTx(tx: TxParser.TransactionStructOutput) {
  console.log("version:", tx.version);
  console.log("inputs:", tx.inputs);
  console.log("outputs:", tx.outputs);
  console.log("locktime:", tx.locktime);
  console.log("hasWitness:", tx.hasWitness);
}

function formatOutput(tx: TxParser.TransactionStructOutput, index: number) {
  return {
    value: tx.outputs[index].value,
    script: tx.outputs[index].script,
  };
}

function formatInput(tx: TxParser.TransactionStructOutput, index: number) {
  return {
    previousHash: tx.inputs[index].previousHash,
    previousIndex: tx.inputs[index].previousIndex,
    sequence: tx.inputs[index].sequence,
    script: tx.inputs[index].script,
    witnesses: [...tx.inputs[index].witnesses],
  };
}

function formatTx(tx: TxParser.TransactionStructOutput) {
  const inputs = [];
  const outputs = [];

  for (let i = 0; i < tx.inputs.length; i++) {
    inputs.push(formatInput(tx, i));
  }

  for (let i = 0; i < tx.outputs.length; i++) {
    outputs.push(formatOutput(tx, i));
  }

  return {
    inputs: inputs,
    outputs: outputs,
    version: tx.version,
    locktime: tx.locktime,
    hasWitness: tx.hasWitness,
  };
}

describe("Transaction Parser", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;

  let btc: TxParserMock;

  before(async () => {
    [OWNER] = await ethers.getSigners();

    const TxParserMock = await ethers.getContractFactory("TxParserMock");
    btc = await TxParserMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("#calculateTxId", () => {
    it("should calculate correctly", async () => {
      let rawTx =
        "0x01000000013652ebc8c4efec4015c4c2e6f7f693bf5307bcc68f59510957e302b89208eb0c060000006a47304402202955e3df921fa6893b898db5117ec92441757d90b485ed3015d427a1aa7631a6022063859ae9fb657b3ceb28c1771076da62e967b3872db6599a08ac982f62ef67810121037a35df3a9314039a2361bd37df3ee846c7a259a7c83f522704517bb7e8748f1effffffff0138ed000000000000160014b9edb07641abc03085f3971e48c6cafbdc854baf00000000";

      let expectedTxid = reverseBytes("0x16a7875987d0be57af2283de4c38f0f4b1ad9c65b936cbc36e101665d8dff891");
      let txid = await btc.calculateTxId(rawTx);

      expect(txid).to.be.eq(expectedTxid);
    });
  });

  describe("#calculateWTxId", () => {
    it("should calculate correctly", async () => {
      let rawTx =
        "0x0200000000010170b05de09b7b57a609b1617c8cb1bbc5f32140bafa238f3340793897c3f2a59c5100000000ffffffff016c440e00000000001976a9149c08058bf18404fe70150761e0f4f786e733b7b688ac0247304402204dca07b9de6aa7ea42dc13cfa261360fbfb807b7bcc94657781c4308a5c40ce902207b3d5e987a3b06c3c0d3d44d79751fd52969056cec0595e36140c7dbd0f4a1f60121026387d8d68fb3deafce92b5d8a0295691edfc131d6568c59c4ed56fabf5ee1a1000000000";

      let expectedWTxid = reverseBytes("0x35308e2c6ccc530a1fa25ef41c8d00e60ff556d060b885ac915c052d075b728d");
      let wtxid = await btc.calculateWTxId(rawTx);

      expect(wtxid).to.be.eq(expectedWTxid);
    });
  });

  describe("#parse", () => {
    it("should parse correctly", async () => {
      let tx = await btc.parseBTCTransaction(
        "0x01000000000101cf337081287de9b93bb8ea17fbaf80e38f24389ab1f5b5519394741e1d91d34d0200000000ffffffff04c7e70800000000001976a914c250b1198b5770a2d00365f0b1660906ddc459e488ac524504000000000017a914c7f0b23c10270adefbe5d2c07b91c281172ca910874cc10100000000001600144d0e22355a0a85c735cd1292ce25dae949f4b538bbd9ea0200000000160014af6aa4350ca438793fa8fc965661df5e4b311640024730440220749a385c9fc2d32728ac4c0ac338ef1ec74a279f8c49677b745e0e6ee55aadad02202f0b7f72980cca5992bfd47a872592cb23bf23cf801e5403f688648feda44f77012103cbb1ede1735af832852b78ebbe9afaf38d233fbaeffe1d90dfb87bbd5a70e14300000000",
      );

      showParsedTx(tx);
      //todo: more fields

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
    it("formatTransaction", async () => {
      let rawTx =
        "0x01000000000101cf337081287de9b93bb8ea17fbaf80e38f24389ab1f5b5519394741e1d91d34d0200000000ffffffff04c7e70800000000001976a914c250b1198b5770a2d00365f0b1660906ddc459e488ac524504000000000017a914c7f0b23c10270adefbe5d2c07b91c281172ca910874cc10100000000001600144d0e22355a0a85c735cd1292ce25dae949f4b538bbd9ea0200000000160014af6aa4350ca438793fa8fc965661df5e4b311640024730440220749a385c9fc2d32728ac4c0ac338ef1ec74a279f8c49677b745e0e6ee55aadad02202f0b7f72980cca5992bfd47a872592cb23bf23cf801e5403f688648feda44f77012103cbb1ede1735af832852b78ebbe9afaf38d233fbaeffe1d90dfb87bbd5a70e14300000000";

      let tx = await btc.parseBTCTransaction(rawTx);

      let formattedTx = await btc.formatTransaction(formatTx(tx), tx.hasWitness);

      expect(formattedTx).to.be.eq(rawTx);

      rawTx =
        "0x0200000001273ad5266d581ad7d22d7292d63646884da6b2e057655ca5e5ef3bb725539385010000006b483045022100feb480f5d8a8db40fc7584d0f66bcc1234f8d153d935aca854b2ae9fd12075100220712b5d66eacd9784e7464c3c86182d1c82cdfce66f83f8390fbf88a9a3d44d600121038a460a2d12fabe8b0b6a4252cee64984720e7bde699cd3099c741d7b04de4eb9fdffffff01effa4300000000001976a9145e44821c5abd14e2162bc25449ff9835a5ba388288ac00000000";

      tx = await btc.parseBTCTransaction(rawTx);

      formattedTx = await btc.formatTransaction(formatTx(tx), tx.hasWitness);

      expect(formattedTx).to.be.eq(rawTx);

      rawTx =
        "0x010000000bf6caa9c815d7057191fe101dcec19da5dc9aa130b7713005d1df1c36af0280f2000000006a473044022005c059272466eb985d7423242efb654b091d6f4f7ac6f22006a873abb5769f7d02201c37aad50ffcb5fd2ad4df83f722351ae0825345d5940400da2777c3c026462201210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdfffffffc03f549b6e4dd9026194ca7696ce69062b86a14112f92b77f22f5d0a55e7496000000006b483045022100b00df4b0578ec22f76a368ddd9e2e7f6003e6ee7a5063d90e2b78e0829b555450220164f295fe4303bfc4a916945830ea7012bcb0d545c8e3610556e47d0a70d2c1801210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffff1b36def255bef66962cd2adee199e03a63b0933a6c36ddd4f44e00953b39cc8a000000006a4730440220716c12d017cd42b646e3a7c324387660f65309aec185f92c25acf8631a10848802204e4e4c92656676f0add33dfab458c7abce4536a9f6ed00e2f5eac1173da9c1ca01210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffff154342956fb660c595dfb3a49515ffa99f680c5c1908c9f2e0c8abb4f444eb76000000006a47304402203dc44ca8ae7e61c2757e87af7f087122c0ae81541e3379a9b105f13bd24bf8e102206da4f3113cc0f0bb823bdc45cbb8361f74857e0362403e0b019e653aaa3672ac01210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffff92cc0b1d060a7048f1e71974d72912edcebf1c8c3cff6d2226c59a8e305aa54e000000006b4830450221008ebedcf877d2a5d4d4adc59daee2ce972c02e59512d73b645f2c321b2002b8b3022053a36c479a7d0a7387886032279b85e6277134131847d3c561502bd9c0e47f7401210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffffb42446198aa01d8fb3fdcff38c1aa2cb03293ca5c509a1f5f07dd38885e9c525000000006b483045022100bd0391fd59fdc8f3ea8bef09bd322cb39a3ef25f77ab86af14d35b471e0fecb002203b82882c23b36861c5b5d45f41ad563546e66a148bdca06d11fbdf23026cef4101210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffff0ea5f647befb4e34ba1347a9efeeb4710db23cfd2b830935e47fded7357a4571000000006b4830450221009c997e6005b6d8463c9f340f631970f6cfdc6d5e0ab8c7d8019afb2e4e2cb3910220391e2d4e8dfa5c676354171984fc34e871c16538692b1997b983209fd429cefa01210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffffc829b7c94a70537070321ff032d0cddae5d78933d272ceee9f91254747f9ae02000000006b4830450221009707a956c94fb829e1c14e050e2e2e925b5f9b5a9b5c739d866d54e8948a4d2e02202f05e24b2f0233248da3bac6343abd16e23da5a158f8431be8c05b81be4c154a01210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffffe10f5908aabd33c577ba73755b0fc59c66e565b2f9bd282af7506f9371df211a000000006a47304402201068855260c6b16ef60684b6e367b0d0ce0c9cc190bc6fae8c8cf7c482b1b2b7022033e70897218c69283bdb5315bd7181cf96862bec5c6b9a1f7ee13e799e4ac44801210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffffc594e81017f56f33596cf9d42ae6b5a728065179d2c7bc38c3f25c0a3af0290c000000006b483045022100f5d65b52b02b85313ce8d6f0f2299f0205ffc273580974e87c0d4ed0ff6c7d3d02204b8c0c4d115084c3e3b29b79b51938ed763124fadc96b9e75bdfa04ecb4dbbcf01210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffff3f6f1f62b719cb7387a9b5b54107fda30d520c7b7312604ac178806ce4299356000000006a4730440220308fc668fd22354c50cd93af6b9cfa02fc444b3476b17f9191f7d1f23a360fbf022019a55dfca913e2ba1ce5a8c10047ea5bc726cba4046c306da89cdffd8d954c3a01210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffff03e6d3fc050000000017a9149f95ba786db3afb2052804ea7945c3e5479bd07487e34205000000000017a9149baa094d1a9f68c22f49228a760bb73695cbfa3a87c86a010000000000160014742d660d7077258430040c0fe114d6490cee7cc300000000";

      tx = await btc.parseBTCTransaction(rawTx);

      formattedTx = await btc.formatTransaction(formatTx(tx), tx.hasWitness);

      expect(formattedTx).to.be.eq(rawTx);
    });

    it("formatCuint", async () => {
      let inputNumber = "0xfd0001";
      let parsed = await btc.parseCuint(inputNumber, 0);

      let formatted = await btc.formatCuint(parsed[0]);

      expect(formatted).to.be.eq(inputNumber);

      inputNumber = "0xfeffffffff";
      parsed = await btc.parseCuint(inputNumber, 0);

      formatted = await btc.formatCuint(parsed[0]);

      expect(formatted).to.be.eq(inputNumber);

      inputNumber = "0xfeff0f14fa";
      parsed = await btc.parseCuint(inputNumber, 0);

      formatted = await btc.formatCuint(parsed[0]);

      expect(formatted).to.be.eq(inputNumber);

      inputNumber = "0xffffffffffffffffff";
      parsed = await btc.parseCuint(inputNumber, 0);

      formatted = await btc.formatCuint(parsed[0]);

      expect(formatted).to.be.eq(inputNumber);

      inputNumber = "0xff01ffbf07efffaafd";
      parsed = await btc.parseCuint(inputNumber, 0);

      formatted = await btc.formatCuint(parsed[0]);

      expect(formatted).to.be.eq(inputNumber);
    });
  });

  describe("#parseCuint", () => {
    it("should parse correctly", async () => {
      let inputNumber = "0xfd0001";
      let parsed = await btc.parseCuint(inputNumber, 0);

      let [expectedNumber, expectedNumberSize] = parseCuint(inputNumber, 0);

      expect(parsed[0]).to.be.eq(expectedNumber);
      expect(parsed[1]).to.be.eq(expectedNumberSize / 2);

      inputNumber = "0xfeffffffff";
      parsed = await btc.parseCuint(inputNumber, 0);

      [expectedNumber, expectedNumberSize] = parseCuint(inputNumber, 0);

      expect(parsed[0]).to.be.eq(expectedNumber);
      expect(parsed[1]).to.be.eq(expectedNumberSize / 2);

      inputNumber = "0xfeff0f14fa";
      parsed = await btc.parseCuint(inputNumber, 0);

      [expectedNumber, expectedNumberSize] = parseCuint(inputNumber, 0);

      expect(parsed[0]).to.be.eq(expectedNumber);
      expect(parsed[1]).to.be.eq(expectedNumberSize / 2);

      inputNumber = "0xffffffffffffffffff";
      parsed = await btc.parseCuint(inputNumber, 0);

      [expectedNumber, expectedNumberSize] = parseCuint(inputNumber, 0);

      expect(parsed[0]).to.be.eq(expectedNumber);
      expect(parsed[1]).to.be.eq(expectedNumberSize / 2);

      inputNumber = "0xff01ffbf07efffaafd";
      parsed = await btc.parseCuint(inputNumber, 0);

      [expectedNumber, expectedNumberSize] = parseCuint(inputNumber, 0);

      expect(parsed[0]).to.be.eq(expectedNumber);
      expect(parsed[1]).to.be.eq(expectedNumberSize / 2);
    });
  });
});
