import { expect } from "chai";
import hre from "hardhat";

import { Reverter } from "@test-helpers";
import { checkTransaction, formatTx, getTxData, getTxDataFilePath, parseCuint, reverseBytes } from "@test-helpers";

import { TxParserMock } from "@ethers-v6";

const { ethers, networkHelpers } = await hre.network.connect();

describe("Transaction Parser", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  let parser: TxParserMock;

  let txData802_368: string;
  let txData568: string;

  const invalidVersionTx =
    "0x03000000000101cf337081287de9b93bb8ea17fbaf80e38f24389ab1f5b5519394741e1d91d34d0200000000ffffffff04c7e70800000000001976a914c250b1198b5770a2d00365f0b1660906ddc459e488ac524504000000000017a914c7f0b23c10270adefbe5d2c07b91c281172ca910874cc10100000000001600144d0e22355a0a85c735cd1292ce25dae949f4b538bbd9ea0200000000160014af6aa4350ca438793fa8fc965661df5e4b311640024730440220749a385c9fc2d32728ac4c0ac338ef1ec74a279f8c49677b745e0e6ee55aadad02202f0b7f72980cca5992bfd47a872592cb23bf23cf801e5403f688648feda44f77012103cbb1ede1735af832852b78ebbe9afaf38d233fbaeffe1d90dfb87bbd5a70e14300000000";
  const invalidFlagTx =
    "0x02000000000201cf251026b2625d4b4ddd8f94dba9205ae963e757177972e5a0a36b446283c1090200000000fdffffff02e6c9010000000000160014b201b5368f2a65048b72f0b4ca3845b1c299a26e0000000000000000116a5d0eff7f818cec82d08bc0a88281d21502483045022100ca4f0302f7e22e589918fe13cb61367baf1b6f4c23b5bae55ba508dc8657243202204d5f7dc80d126f7c35440a6ea5718938bcf7cb8c9307a06d6f1f585c38fbd7c4012103a46fa6d023dddc643cfb5a26753dabf1f6bdf366f3d5f101cf01abe9ffb70bb600000000";
  const shortFlagTx = "0x0200000000";
  const shortTx = "0x01000000";

  before(async () => {
    const TxParserMock = await ethers.getContractFactory("TxParserMock");
    parser = await TxParserMock.deploy();

    txData802_368 = getTxDataFilePath("txs_0_10_block_802_368.json");
    txData568 = getTxDataFilePath("tx_0_block_568.json");

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("#calculateTxId", () => {
    it("should calculate correctly", async () => {
      let rawTx =
        "0x01000000013652ebc8c4efec4015c4c2e6f7f693bf5307bcc68f59510957e302b89208eb0c060000006a47304402202955e3df921fa6893b898db5117ec92441757d90b485ed3015d427a1aa7631a6022063859ae9fb657b3ceb28c1771076da62e967b3872db6599a08ac982f62ef67810121037a35df3a9314039a2361bd37df3ee846c7a259a7c83f522704517bb7e8748f1effffffff0138ed000000000000160014b9edb07641abc03085f3971e48c6cafbdc854baf00000000";

      let expectedTxid = reverseBytes("0x16a7875987d0be57af2283de4c38f0f4b1ad9c65b936cbc36e101665d8dff891");
      let txid = await parser.calculateTxId(rawTx);

      expect(txid).to.be.eq(expectedTxid);
    });
  });

  describe("#parse", () => {
    it("should parse correctly", async () => {
      for (let i = 0; i < 10; ++i) {
        const actualTxData = getTxData(txData802_368, i);

        const parsedResult = await parser.parseBTCTransaction("0x" + actualTxData.hex);

        checkTransaction(parsedResult, actualTxData);
      }
    });

    it("should parse correctly when transaction is without witness", async () => {
      const actualTxData = getTxData(txData568, 0);

      const parsedResult = await parser.parseBTCTransaction("0x" + actualTxData.hex);

      checkTransaction(parsedResult, actualTxData);
    });

    it("should revert", async () => {
      await expect(parser.parseBTCTransaction(invalidVersionTx))
        .to.be.revertedWithCustomError(parser, "UnsupportedVersion")
        .withArgs(3);

      await expect(parser.parseBTCTransaction(invalidFlagTx))
        .to.be.revertedWithCustomError(parser, "InvalidFlag")
        .withArgs(2);

      await expect(parser.parseBTCTransaction(shortFlagTx))
        .to.be.revertedWithCustomError(parser, "InvalidFlag")
        .withArgs(0);

      await expect(parser.parseBTCTransaction(shortTx)).to.be.revertedWithCustomError(parser, "BufferOverflow");
    });
  });

  describe("#format", () => {
    it("formatTransaction", async () => {
      let rawTx =
        "0x01000000000101cf337081287de9b93bb8ea17fbaf80e38f24389ab1f5b5519394741e1d91d34d0200000000ffffffff04c7e70800000000001976a914c250b1198b5770a2d00365f0b1660906ddc459e488ac524504000000000017a914c7f0b23c10270adefbe5d2c07b91c281172ca910874cc10100000000001600144d0e22355a0a85c735cd1292ce25dae949f4b538bbd9ea0200000000160014af6aa4350ca438793fa8fc965661df5e4b311640024730440220749a385c9fc2d32728ac4c0ac338ef1ec74a279f8c49677b745e0e6ee55aadad02202f0b7f72980cca5992bfd47a872592cb23bf23cf801e5403f688648feda44f77012103cbb1ede1735af832852b78ebbe9afaf38d233fbaeffe1d90dfb87bbd5a70e14300000000";

      let tx = await parser.parseBTCTransaction(rawTx);

      let formattedTx = await parser.formatTransaction(formatTx(tx), tx.hasWitness);

      expect(formattedTx).to.be.eq(rawTx);

      rawTx =
        "0x0200000001273ad5266d581ad7d22d7292d63646884da6b2e057655ca5e5ef3bb725539385010000006b483045022100feb480f5d8a8db40fc7584d0f66bcc1234f8d153d935aca854b2ae9fd12075100220712b5d66eacd9784e7464c3c86182d1c82cdfce66f83f8390fbf88a9a3d44d600121038a460a2d12fabe8b0b6a4252cee64984720e7bde699cd3099c741d7b04de4eb9fdffffff01effa4300000000001976a9145e44821c5abd14e2162bc25449ff9835a5ba388288ac00000000";

      tx = await parser.parseBTCTransaction(rawTx);

      formattedTx = await parser.formatTransaction(formatTx(tx), tx.hasWitness);

      expect(formattedTx).to.be.eq(rawTx);

      rawTx =
        "0x010000000bf6caa9c815d7057191fe101dcec19da5dc9aa130b7713005d1df1c36af0280f2000000006a473044022005c059272466eb985d7423242efb654b091d6f4f7ac6f22006a873abb5769f7d02201c37aad50ffcb5fd2ad4df83f722351ae0825345d5940400da2777c3c026462201210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdfffffffc03f549b6e4dd9026194ca7696ce69062b86a14112f92b77f22f5d0a55e7496000000006b483045022100b00df4b0578ec22f76a368ddd9e2e7f6003e6ee7a5063d90e2b78e0829b555450220164f295fe4303bfc4a916945830ea7012bcb0d545c8e3610556e47d0a70d2c1801210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffff1b36def255bef66962cd2adee199e03a63b0933a6c36ddd4f44e00953b39cc8a000000006a4730440220716c12d017cd42b646e3a7c324387660f65309aec185f92c25acf8631a10848802204e4e4c92656676f0add33dfab458c7abce4536a9f6ed00e2f5eac1173da9c1ca01210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffff154342956fb660c595dfb3a49515ffa99f680c5c1908c9f2e0c8abb4f444eb76000000006a47304402203dc44ca8ae7e61c2757e87af7f087122c0ae81541e3379a9b105f13bd24bf8e102206da4f3113cc0f0bb823bdc45cbb8361f74857e0362403e0b019e653aaa3672ac01210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffff92cc0b1d060a7048f1e71974d72912edcebf1c8c3cff6d2226c59a8e305aa54e000000006b4830450221008ebedcf877d2a5d4d4adc59daee2ce972c02e59512d73b645f2c321b2002b8b3022053a36c479a7d0a7387886032279b85e6277134131847d3c561502bd9c0e47f7401210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffffb42446198aa01d8fb3fdcff38c1aa2cb03293ca5c509a1f5f07dd38885e9c525000000006b483045022100bd0391fd59fdc8f3ea8bef09bd322cb39a3ef25f77ab86af14d35b471e0fecb002203b82882c23b36861c5b5d45f41ad563546e66a148bdca06d11fbdf23026cef4101210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffff0ea5f647befb4e34ba1347a9efeeb4710db23cfd2b830935e47fded7357a4571000000006b4830450221009c997e6005b6d8463c9f340f631970f6cfdc6d5e0ab8c7d8019afb2e4e2cb3910220391e2d4e8dfa5c676354171984fc34e871c16538692b1997b983209fd429cefa01210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffffc829b7c94a70537070321ff032d0cddae5d78933d272ceee9f91254747f9ae02000000006b4830450221009707a956c94fb829e1c14e050e2e2e925b5f9b5a9b5c739d866d54e8948a4d2e02202f05e24b2f0233248da3bac6343abd16e23da5a158f8431be8c05b81be4c154a01210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffffe10f5908aabd33c577ba73755b0fc59c66e565b2f9bd282af7506f9371df211a000000006a47304402201068855260c6b16ef60684b6e367b0d0ce0c9cc190bc6fae8c8cf7c482b1b2b7022033e70897218c69283bdb5315bd7181cf96862bec5c6b9a1f7ee13e799e4ac44801210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffffc594e81017f56f33596cf9d42ae6b5a728065179d2c7bc38c3f25c0a3af0290c000000006b483045022100f5d65b52b02b85313ce8d6f0f2299f0205ffc273580974e87c0d4ed0ff6c7d3d02204b8c0c4d115084c3e3b29b79b51938ed763124fadc96b9e75bdfa04ecb4dbbcf01210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffff3f6f1f62b719cb7387a9b5b54107fda30d520c7b7312604ac178806ce4299356000000006a4730440220308fc668fd22354c50cd93af6b9cfa02fc444b3476b17f9191f7d1f23a360fbf022019a55dfca913e2ba1ce5a8c10047ea5bc726cba4046c306da89cdffd8d954c3a01210396caf2fc5b7526975c452d665804457fd287c73e25a0025fe59dd88a61c735dbfdffffff03e6d3fc050000000017a9149f95ba786db3afb2052804ea7945c3e5479bd07487e34205000000000017a9149baa094d1a9f68c22f49228a760bb73695cbfa3a87c86a010000000000160014742d660d7077258430040c0fe114d6490cee7cc300000000";

      tx = await parser.parseBTCTransaction(rawTx);

      formattedTx = await parser.formatTransaction(formatTx(tx), tx.hasWitness);

      expect(formattedTx).to.be.eq(rawTx);
    });

    it("formatCuint", async () => {
      let inputNumber = "0xfd0001";
      let parsed = await parser.parseCuint(inputNumber);

      let formatted = await parser.formatCuint(parsed[0]);

      expect(formatted).to.be.eq(inputNumber);

      inputNumber = "0xfeffffffff";
      parsed = await parser.parseCuint(inputNumber);

      formatted = await parser.formatCuint(parsed[0]);

      expect(formatted).to.be.eq(inputNumber);

      inputNumber = "0xfeff0f14fa";
      parsed = await parser.parseCuint(inputNumber);

      formatted = await parser.formatCuint(parsed[0]);

      expect(formatted).to.be.eq(inputNumber);

      inputNumber = "0xffffffffffffffffff";
      parsed = await parser.parseCuint(inputNumber);

      formatted = await parser.formatCuint(parsed[0]);

      expect(formatted).to.be.eq(inputNumber);

      inputNumber = "0xff0000000001000000";
      parsed = await parser.parseCuint(inputNumber);

      formatted = await parser.formatCuint(parsed[0]);

      expect(formatted).to.be.eq(inputNumber);

      inputNumber = "0xff01ffbf07efffaafd";
      parsed = await parser.parseCuint(inputNumber);

      formatted = await parser.formatCuint(parsed[0]);

      expect(formatted).to.be.eq(inputNumber);
    });
  });

  describe("#parseCuint", () => {
    it("should parse correctly", async () => {
      let inputNumber = "0xfd0001";
      let parsed = await parser.parseCuint(inputNumber);

      let [expectedNumber, expectedNumberSize] = parseCuint(inputNumber, 0);

      expect(parsed[0]).to.be.eq(expectedNumber);
      expect(parsed[1]).to.be.eq(expectedNumberSize / 2);

      inputNumber = "0xfeffffffff";
      parsed = await parser.parseCuint(inputNumber);

      [expectedNumber, expectedNumberSize] = parseCuint(inputNumber, 0);

      expect(parsed[0]).to.be.eq(expectedNumber);
      expect(parsed[1]).to.be.eq(expectedNumberSize / 2);

      inputNumber = "0xfeff0f14fa";
      parsed = await parser.parseCuint(inputNumber);

      [expectedNumber, expectedNumberSize] = parseCuint(inputNumber, 0);

      expect(parsed[0]).to.be.eq(expectedNumber);
      expect(parsed[1]).to.be.eq(expectedNumberSize / 2);

      inputNumber = "0xffffffffffffffffff";
      parsed = await parser.parseCuint(inputNumber);

      [expectedNumber, expectedNumberSize] = parseCuint(inputNumber, 0);

      expect(parsed[0]).to.be.eq(expectedNumber);
      expect(parsed[1]).to.be.eq(expectedNumberSize / 2);

      inputNumber = "0xff0000000001000000";
      parsed = await parser.parseCuint(inputNumber);

      [expectedNumber, expectedNumberSize] = parseCuint(inputNumber, 0);

      expect(parsed[0]).to.be.eq(expectedNumber);
      expect(parsed[1]).to.be.eq(expectedNumberSize / 2);

      inputNumber = "0xff01ffbf07efffaafd";
      parsed = await parser.parseCuint(inputNumber);

      [expectedNumber, expectedNumberSize] = parseCuint(inputNumber, 0);

      expect(parsed[0]).to.be.eq(expectedNumber);
      expect(parsed[1]).to.be.eq(expectedNumberSize / 2);
    });
  });

  describe("#isTransaction", () => {
    it("should return true for a valid transaction", async () => {
      for (let i = 0; i < 10; ++i) {
        const actualTxData = getTxData(txData802_368, i);

        expect(await parser.isTransaction("0x" + actualTxData.hex)).to.be.true;
      }
    });

    it("should return false for a invalid transaction", async () => {
      const zeroVersion =
        "0x00000000010000000000000000000000000000000000000000000000000000000000000000ffffffff0804ffff001d024006ffffffff0100f2052a0100000043410431e1cb363a76c8f15f008026af465f48aaca8bb4c8ce4b3880ec9efa1db59c3a11274f85db20508abd28bae4b10e5d6b871274d86da351a3837895dd4b20dbadac00000000";
      const invalidVersionBytes1 =
        "0x01010000010000000000000000000000000000000000000000000000000000000000000000ffffffff0804ffff001d024006ffffffff0100f2052a0100000043410431e1cb363a76c8f15f008026af465f48aaca8bb4c8ce4b3880ec9efa1db59c3a11274f85db20508abd28bae4b10e5d6b871274d86da351a3837895dd4b20dbadac00000000";
      const invalidVersionBytes2 =
        "0x01000500010000000000000000000000000000000000000000000000000000000000000000ffffffff0804ffff001d024006ffffffff0100f2052a0100000043410431e1cb363a76c8f15f008026af465f48aaca8bb4c8ce4b3880ec9efa1db59c3a11274f85db20508abd28bae4b10e5d6b871274d86da351a3837895dd4b20dbadac00000000";
      const invalidVersionBytes3 =
        "0x010000ff010000000000000000000000000000000000000000000000000000000000000000ffffffff0804ffff001d024006ffffffff0100f2052a0100000043410431e1cb363a76c8f15f008026af465f48aaca8bb4c8ce4b3880ec9efa1db59c3a11274f85db20508abd28bae4b10e5d6b871274d86da351a3837895dd4b20dbadac00000000";
      const invalidWitnessTx =
        "0x02000000000f013bb96379452d332e87150d75057b5f553c4a8d421c1f046ee4aa59c8bd5a811f0100000000fdffffff02a8c51900000000001600146e20dfddae7c9a3bde8a0e21aa631644394efb0ce5c7820a0000000016001453fc77b67d4cd25db14bb90efbbb674187e72dda024730440220241048cf1f79f7b7dd00b48a7a3b218494e2917b3625fa85f9e494ed7f889963022063aff33776141adcd90ac1990d1d8d1a853f6c0c9960dfccc0ee6e3317d81491012102a83617720912ae0119692e4e1c8118682c7365983119c890d972d7d59d5cd3649ebb0d00";
      const invalidInputCount =
        "0x020000000001902e0d83414d9b5ee709773a0c1ce2325cad3b650468755d244087304e99f0ae450000000000010000800190650000000000001600148c676a1c175fdc55c370b7574fad98d5be7506970140067a7b2cea28dab27de68fee4ea92580cb307d687c5ab257a46d2c13018f755e2fce754bd4c649902cd63ec0ee657c2ab3c3d98521ac58fedaa08e4bef5f355700000000";
      const invalidScriptLen =
        "0x020000000001012e0d83414d9b5ee709773a0c1ce2325cad3b650468755d244087304e99f0ae4500000000ff010000800190650000000000001600148c676a1c175fdc55c370b7574fad98d5be7506970140067a7b2cea28dab27de68fee4ea92580cb307d687c5ab257a46d2c13018f755e2fce754bd4c649902cd63ec0ee657c2ab3c3d98521ac58fedaa08e4bef5f355700000000";
      const invalidOutputCount =
        "0x020000000001012e0d83414d9b5ee709773a0c1ce2325cad3b650468755d244087304e99f0ae45000000000001000080af90650000000000001600148c676a1c175fdc55c370b7574fad98d5be7506970140067a7b2cea28dab27de68fee4ea92580cb307d687c5ab257a46d2c13018f755e2fce754bd4c649902cd63ec0ee657c2ab3c3d98521ac58fedaa08e4bef5f355700000000";
      const invalidOutputScriptLen =
        "0x020000000001012e0d83414d9b5ee709773a0c1ce2325cad3b650468755d244087304e99f0ae45000000000001000080019065000000000000ee00148c676a1c175fdc55c370b7574fad98d5be7506970140067a7b2cea28dab27de68fee4ea92580cb307d687c5ab257a46d2c13018f755e2fce754bd4c649902cd63ec0ee657c2ab3c3d98521ac58fedaa08e4bef5f355700000000";
      const invalidWitnessCount =
        "0x020000000001012e0d83414d9b5ee709773a0c1ce2325cad3b650468755d244087304e99f0ae450000000000010000800190650000000000001600148c676a1c175fdc55c370b7574fad98d5be750697ff40067a7b2cea28dab27de68fee4ea92580cb307d687c5ab257a46d2c13018f755e2fce754bd4c649902cd63ec0ee657c2ab3c3d98521ac58fedaa08e4bef5f355700000000";
      const invalidWScriptLen =
        "0x020000000001012e0d83414d9b5ee709773a0c1ce2325cad3b650468755d244087304e99f0ae450000000000010000800190650000000000001600148c676a1c175fdc55c370b7574fad98d5be7506970150067a7b2cea28dab27de68fee4ea92580cb307d687c5ab257a46d2c13018f755e2fce754bd4c649902cd63ec0ee657c2ab3c3d98521ac58fedaa08e4bef5f355700000000";
      const tooLong =
        "0x020000000001012e0d83414d9b5ee709773a0c1ce2325cad3b650468755d244087304e99f0ae450000000000010000800190650000000000001600148c676a1c175fdc55c370b7574fad98d5be7506970140067a7b2cea28dab27de68fee4ea92580cb307d687c5ab257a46d2c13018f755e2fce754bd4c649902cd63ec0ee657c2ab3c3d98521ac58fedaa08e4bef5f355700000000ff";

      expect(await parser.isTransaction(zeroVersion)).to.be.false;
      expect(await parser.isTransaction(invalidVersionTx)).to.be.false;
      expect(await parser.isTransaction(invalidFlagTx)).to.be.false;
      expect(await parser.isTransaction(shortFlagTx)).to.be.false;
      expect(await parser.isTransaction(shortTx)).to.be.false;
      expect(await parser.isTransaction(invalidVersionBytes1)).to.be.false;
      expect(await parser.isTransaction(invalidVersionBytes2)).to.be.false;
      expect(await parser.isTransaction(invalidVersionBytes3)).to.be.false;
      expect(await parser.isTransaction(invalidWitnessTx)).to.be.false;
      expect(await parser.isTransaction(invalidInputCount)).to.be.false;
      expect(await parser.isTransaction(invalidScriptLen)).to.be.false;
      expect(await parser.isTransaction(invalidOutputCount)).to.be.false;
      expect(await parser.isTransaction(invalidOutputScriptLen)).to.be.false;
      expect(await parser.isTransaction(invalidWitnessCount)).to.be.false;
      expect(await parser.isTransaction(invalidWScriptLen)).to.be.false;
      expect(await parser.isTransaction(tooLong)).to.be.false;
    });
  });
});
