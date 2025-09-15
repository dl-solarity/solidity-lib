import { expect } from "chai";
import hre from "hardhat";

import { sha256 } from "ethers";

import { MerkleRawProofParser, Reverter, addHexPrefix, reverseBytes } from "@test-helpers";

import { TxMerkleProofMock } from "@ethers-v6";

const { ethers, networkHelpers } = await hre.network.connect();

describe("TxMerkleProof", () => {
  const reverter: Reverter = new Reverter(networkHelpers);

  let txMerkleProof: TxMerkleProofMock;

  before("setup", async () => {
    txMerkleProof = await ethers.deployContract("TxMerkleProofMock");

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("#verifyTX", () => {
    const merkleRoot1 = "0e3e2357e806b6cdb1f70b54c3a3a17b6714ee1f0e68bebb44a74b1efd512098";
    const merkleRoot943 = "a660e96c749aca24d055bf0754931b0aa036bf9a799836df1e08c0c57e7cc7df";
    const merkleRoot546 = "e10a7f8442ea6cc6803a2b83713765c0b1199924110205f601f90fef125e7dfe";
    const merkleRoot586 = "197b3d968ce463aa5da7d8eeba8af35eba80ded4e4fe6808e6cc0dd1c069594d";

    it("should correctly verify when one transaction is in the block", async () => {
      const txid = "0e3e2357e806b6cdb1f70b54c3a3a17b6714ee1f0e68bebb44a74b1efd512098";
      const rawProof =
        "010000006fe28c0ab6f1b372c1a6a246ae63f74f931e8365e15a089c68d6190000000000982051fd1e4ba744bbbe680e1fee14677ba1a3c3540bf7b1cdb606e857233e0e61bc6649ffff001d01e362990100000001982051fd1e4ba744bbbe680e1fee14677ba1a3c3540bf7b1cdb606e857233e0e0101";

      const parser = new MerkleRawProofParser(txid, rawProof);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot1),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;
    });

    it("should correctly verify the first transaction in a block with two transactions", async () => {
      const txid = "7fad6c73cf98d9d5d158a918504ec2ab72131bea0dc8b9c5b6ca397b7673bf5e";
      const rawProof =
        "010000009ba7a269117149ab6fbd5830d9e9e18076b3374c5187d0a196f8ed0200000000dfc77c7ec5c0081edf3698799abf36a00a1b935407bf55d024ca9a746ce960a6f38a7349ffff001d2e7656c402000000025ebf73767b39cab6c5b9c80dea1b1372abc24e5018a958d1d5d998cf736cad7ff6bf258652a9addf1e19b5d7e051984101ccff5d30ae2805088d991cf7c14c3e0103";

      const parser = new MerkleRawProofParser(txid, rawProof);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot943),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;
    });

    it("should correctly verify the second transaction in a block with two transactions", async () => {
      const txid = "3e4cc1f71c998d080528ae305dffcc01419851e0d7b5191edfada9528625bff6";
      const rawProof =
        "010000009ba7a269117149ab6fbd5830d9e9e18076b3374c5187d0a196f8ed0200000000dfc77c7ec5c0081edf3698799abf36a00a1b935407bf55d024ca9a746ce960a6f38a7349ffff001d2e7656c402000000025ebf73767b39cab6c5b9c80dea1b1372abc24e5018a958d1d5d998cf736cad7ff6bf258652a9addf1e19b5d7e051984101ccff5d30ae2805088d991cf7c14c3e0105";

      const parser = new MerkleRawProofParser(txid, rawProof);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot943),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;
    });

    it("should correctly verify a transaction from a block with four transactions", async () => {
      const txid = "e980fe9f792d014e73b95203dc1335c5f9ce19ac537a419e6df5b47aecb93b70";
      const rawProof =
        "0100000075616236cc2126035fadb38deb65b9102cc2c41c09cdf29fc051906800000000fe7d5e12ef0ff901f6050211249919b1c0653771832b3a80c66cea42847f0ae1d4d26e49ffff001d00f0a4410400000003703bb9ec7ab4f56d9e417a53ac19cef9c53513dc0352b9734e012d799ffe80e95f9a06d3acdceb56be1bfeaa3e8a25e62d182fa24fefe899d1c17f1dad4c2028e91eb9b0ede8c4735562363d58e31e061b71826c50cfdcccda62dadb25bad8b10107";

      const parser = new MerkleRawProofParser(txid, rawProof);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot546),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;
    });

    it("should correctly verify a transaction without a pair from a block with three transactions.", async () => {
      const txid = "6bf363548b08aa8761e278be802a2d84b8e40daefe8150f9af7dd7b65a0de49f";
      const rawProof =
        "0100000038babc9586a5fcd60713573494f4377e7c401c33aa24729a4f6cff46000000004d5969c0d10dcce60868fee4d4de80ba5ef38abaeed8a75daa63e48c963d7b1950476f49ffff001d2d979137030000000294ccb10b934793fafb274abe797568b1292347dcf79ceba003101e57e559f4ba9fe40d5ab6d77daff95081feae0de4b8842d2a80be78e26187aa088b5463f36b010d";

      const parser = new MerkleRawProofParser(txid, rawProof);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot586),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;
    });

    it("should correctly verify from a block with three transactions", async () => {
      const txid = "4d6edbeb62735d45ff1565385a8b0045f066055c9425e21540ea7a8060f08bf2";
      const rawProof =
        "0100000038babc9586a5fcd60713573494f4377e7c401c33aa24729a4f6cff46000000004d5969c0d10dcce60868fee4d4de80ba5ef38abaeed8a75daa63e48c963d7b1950476f49ffff001d2d979137030000000343bcd0e95471f68ed30cdadf0ce654fb44f859bf3e364dc9b08014cdba2457d4f28bf060807aea4015e225945c0566f045008b5a386515ff455d7362ebdb6e4df0c5d029ea79cc893cb8f2fb990a1a3e9a4b9188fd837c66821bd0acc11c85ca010b";

      const parser = new MerkleRawProofParser(txid, rawProof);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot586),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;
    });

    it("should correctly verify from a block with six transactions", async () => {
      const merkleRoot2812 = "289a86c44c4698fd8f181929dc2dd3c25820c959eab28980b27bb3cf8fcacb65";

      const rawProof0 =
        "01000000a4c4e3441c87f39b28b82872de79b57714253c95be052f27f155fe210000000065cbca8fcfb37bb28089b2ea59c92058c2d32ddc2919188ffd98464cc4869a286bcc8749ffff001d1f8015ab06000000047bfaf4b093e82afa7b071a1f15336077f25fdea22a0cfda67573ada4f445c173944badc33f9a723eb1c85dde24374e6dee9259ef4cfa6a10b2fd05b6e55be4002a576b5197fff1776ac8145dfe4946f8ab6b1d28a6c3978365873b7b872a62959d4237a38fded228eccb89962a3cc4b542760a8b74e8d7ee71ab95bc40d06e8d010f";
      const txid0 = "73c145f4a4ad7375a6fd0c2aa2de5ff2776033151f1a077bfa2ae893b0f4fa7b";

      let parser = new MerkleRawProofParser(txid0, rawProof0);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot2812),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;

      const rawProof1 =
        "01000000a4c4e3441c87f39b28b82872de79b57714253c95be052f27f155fe210000000065cbca8fcfb37bb28089b2ea59c92058c2d32ddc2919188ffd98464cc4869a286bcc8749ffff001d1f8015ab06000000047bfaf4b093e82afa7b071a1f15336077f25fdea22a0cfda67573ada4f445c173944badc33f9a723eb1c85dde24374e6dee9259ef4cfa6a10b2fd05b6e55be4002a576b5197fff1776ac8145dfe4946f8ab6b1d28a6c3978365873b7b872a62959d4237a38fded228eccb89962a3cc4b542760a8b74e8d7ee71ab95bc40d06e8d0117";
      const txid1 = "00e45be5b605fdb2106afa4cef5992ee6d4e3724de5dc8b13e729a3fc3ad4b94";

      parser = new MerkleRawProofParser(txid1, rawProof1);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot2812),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;

      const rawProof2 =
        "01000000a4c4e3441c87f39b28b82872de79b57714253c95be052f27f155fe210000000065cbca8fcfb37bb28089b2ea59c92058c2d32ddc2919188ffd98464cc4869a286bcc8749ffff001d1f8015ab06000000045b3cc52f9defcdc1e47b3d3658b8b2b84692747a0d2281a6edcdc50ecde5a67b6d65dcedf2f743b935bb700a30285d395c0b42c78f3f143530f7886edda6c174258f81228318c90cb2d67aba535674a43c1fc5c448b000330ca8281e26681f139d4237a38fded228eccb89962a3cc4b542760a8b74e8d7ee71ab95bc40d06e8d011b";
      const txid2 = "74c1a6dd6e88f73035143f8fc7420b5c395d28300a70bb35b943f7f2eddc656d";

      parser = new MerkleRawProofParser(txid2, rawProof2);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot2812),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;

      const rawProof3 =
        "01000000a4c4e3441c87f39b28b82872de79b57714253c95be052f27f155fe210000000065cbca8fcfb37bb28089b2ea59c92058c2d32ddc2919188ffd98464cc4869a286bcc8749ffff001d1f8015ab06000000045b3cc52f9defcdc1e47b3d3658b8b2b84692747a0d2281a6edcdc50ecde5a67b6d65dcedf2f743b935bb700a30285d395c0b42c78f3f143530f7886edda6c174258f81228318c90cb2d67aba535674a43c1fc5c448b000330ca8281e26681f139d4237a38fded228eccb89962a3cc4b542760a8b74e8d7ee71ab95bc40d06e8d012b";
      const txid3 = "131f68261e28a80c3300b048c4c51f3ca4745653ba7ad6b20cc9188322818f25";

      parser = new MerkleRawProofParser(txid3, rawProof3);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot2812),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;

      const rawProof4 =
        "01000000a4c4e3441c87f39b28b82872de79b57714253c95be052f27f155fe210000000065cbca8fcfb37bb28089b2ea59c92058c2d32ddc2919188ffd98464cc4869a286bcc8749ffff001d1f8015ab0600000003647b2d4aa04c7bb35802127c7d46f856dc7f6889ca602e2aceef4f44c4d63d5c378bf40d067f72bc8e31e05ff70c42feebfbf9c7f6c7dd67ac619b8018e24ba63f29ffe66383e56c9db6bf8d09df2e50b52ef13f5c9d7149269ff757d1b65d8f011d";
      const txid4 = "a64be218809b61ac67ddc7f6c7f9fbebfe420cf75fe0318ebc727f060df48b37";

      parser = new MerkleRawProofParser(txid4, rawProof4);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot2812),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;

      const rawProof5 =
        "01000000a4c4e3441c87f39b28b82872de79b57714253c95be052f27f155fe210000000065cbca8fcfb37bb28089b2ea59c92058c2d32ddc2919188ffd98464cc4869a286bcc8749ffff001d1f8015ab0600000003647b2d4aa04c7bb35802127c7d46f856dc7f6889ca602e2aceef4f44c4d63d5c378bf40d067f72bc8e31e05ff70c42feebfbf9c7f6c7dd67ac619b8018e24ba63f29ffe66383e56c9db6bf8d09df2e50b52ef13f5c9d7149269ff757d1b65d8f012d";
      const txid5 = "8f5db6d157f79f2649719d5c3ff12eb5502edf098dbfb69d6ce58363e6ff293f";

      parser = new MerkleRawProofParser(txid5, rawProof5);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot2812),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;
    });

    it("should correctly return false when the txid is invalid", async () => {
      const txid = "4d6edbeb62735d45ff1565385a8b0045f066055c9425e21540ea7a8060f08bf2";
      const rawProof =
        "0100000038babc9586a5fcd60713573494f4377e7c401c33aa24729a4f6cff46000000004d5969c0d10dcce60868fee4d4de80ba5ef38abaeed8a75daa63e48c963d7b1950476f49ffff001d2d979137030000000343bcd0e95471f68ed30cdadf0ce654fb44f859bf3e364dc9b08014cdba2457d4f28bf060807aea4015e225945c0566f045008b5a386515ff455d7362ebdb6e4df0c5d029ea79cc893cb8f2fb990a1a3e9a4b9188fd837c66821bd0acc11c85ca010b";

      const parser = new MerkleRawProofParser(txid, rawProof);
      const wrongTxId = "0x0e3e2357e806b6cdb1f70b54c3a3a17b6714ee1f0e68bebb44a74b1efd512098";

      expect(
        await txMerkleProof.verify(parser.getSiblings(), reverseBytes(merkleRoot586), wrongTxId, parser.getTxIndex()),
      ).to.be.false;
    });

    it("should verify different transactions from a block with 2 593 transactions", async () => {
      const merkleRoot802368 = "7718a5c199d9a5b6ad3d1424db6d4212bbbc1cbfe573caf58f129d24e40b15eb";

      const rawProof0 =
        "0000ff3f17dd318436d66875376a55a10962c3e7fe1e7c8f1a4e03000000000000000000eb150be4249d128ff5ca73e5bf1cbcbb12426ddb24143dadb6a5d999c1a518774486d3645b5f0517c4394600210a00000d35123e12b3b4dc8cb918d468def982ea1a840a67ddd7cb6b1270f9e0355253aac77311cea01ff3b36793c470cc87d5668dd0dcfc41b1d9aaf7c0e051b66efa581dbcd747c5fd0e09eaaed3b62c91700ed29661d0ac170798fa2da2b39aff33e50e9d6247e7731072664883f78619eeab9113952e4126659b99b30fa903d01843117ceca7c7e380d71b6d7310e343ba5a16fa0c14702d1330912413c2873b20f575174e47d42e4362b7d1c8e0bb821678113a0c73735f6e1863a6a85f4168d84605a259d66b6197adbb7afc641a3f0bca0755e7920ba5d89fa290a163120a124c33209ed27356ad641bd20c78b1c4e3518b1fca3142bf26b4e96cb4359dbb8306fc8cae8ac8104202e2bafd2bf6e864255e72b332f7dfb5db28d94191f82fb8453dfdfb0536b6044b1638ec0ba42b3d998da0b288a17999da9736c28ed34fb09431269a1723d450e37c989434823dc6f1b1f6958159204067b31dccbbbd956e8bd28769f43cf1870fefbee92e99b2ae0f150d4b99ba61fcb075b6ed7156c2cd30df591bf3ae056ad2e28324fe668147c9c3fcb90c0a275e6e0a92137a94cea48f04ff1f0000";
      const txid0 = "0xaa535235e0f970126bcbd7dd670a841aea82f9de68d418b98cdcb4b3123e1235";

      let parser = new MerkleRawProofParser(txid0, rawProof0);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot802368),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;

      const rawProof1 =
        "0000ff3f17dd318436d66875376a55a10962c3e7fe1e7c8f1a4e03000000000000000000eb150be4249d128ff5ca73e5bf1cbcbb12426ddb24143dadb6a5d999c1a518774486d3645b5f0517c4394600210a00000d35123e12b3b4dc8cb918d468def982ea1a840a67ddd7cb6b1270f9e0355253aac77311cea01ff3b36793c470cc87d5668dd0dcfc41b1d9aaf7c0e051b66efa581dbcd747c5fd0e09eaaed3b62c91700ed29661d0ac170798fa2da2b39aff33e50e9d6247e7731072664883f78619eeab9113952e4126659b99b30fa903d01843117ceca7c7e380d71b6d7310e343ba5a16fa0c14702d1330912413c2873b20f575174e47d42e4362b7d1c8e0bb821678113a0c73735f6e1863a6a85f4168d84605a259d66b6197adbb7afc641a3f0bca0755e7920ba5d89fa290a163120a124c33209ed27356ad641bd20c78b1c4e3518b1fca3142bf26b4e96cb4359dbb8306fc8cae8ac8104202e2bafd2bf6e864255e72b332f7dfb5db28d94191f82fb8453dfdfb0536b6044b1638ec0ba42b3d998da0b288a17999da9736c28ed34fb09431269a1723d450e37c989434823dc6f1b1f6958159204067b31dccbbbd956e8bd28769f43cf1870fefbee92e99b2ae0f150d4b99ba61fcb075b6ed7156c2cd30df591bf3ae056ad2e28324fe668147c9c3fcb90c0a275e6e0a92137a94cea48f04ff2f0000";
      const txid1 = "58fa6eb651e0c0f7aad9b141fcdcd08d66d587cc70c49367b3f31fa0ce1173c7";

      parser = new MerkleRawProofParser(txid1, rawProof1);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot802368),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;

      const rawProof170 =
        "0000ff3f17dd318436d66875376a55a10962c3e7fe1e7c8f1a4e03000000000000000000eb150be4249d128ff5ca73e5bf1cbcbb12426ddb24143dadb6a5d999c1a518774486d3645b5f0517c4394600210a00000d07942ef35c0495b4dee8440187b003acd11aede3dcf5f9af722f0de68f6d23097ec2efee87a99ab31bbc74c55d91748cd5bb4788e325d179f33cfc994ea688822af9d9c6981d360cfa7392390a68434d4321bb30139b0bc8a8d95603a62214749d2c92391d2f44613d997b08306c0c186dbff3998ac6af13b8c0df03a2e02ca89d86acff9b64b661b0856cae4cc3844b462459a775888b13db17171a8bf1ea7f163c2d25b01939af6a6334ed7ab248a41e32559aa2e89aef41d138b3a2b9499bcee0b8c7e28c679016190bb08b941aadc50f34232f6da759507e6a30eb9421ef2c1544e750f1f38e63fe25d104e599325a40628fac8761c78e45adbdab8b6e5dbe795d5290059294a376d48fe1c7b7fd0f6ec0e7d7869f8f5d3bfd1f6d40131c3dfdfb0536b6044b1638ec0ba42b3d998da0b288a17999da9736c28ed34fb09431269a1723d450e37c989434823dc6f1b1f6958159204067b31dccbbbd956e8bd28769f43cf1870fefbee92e99b2ae0f150d4b99ba61fcb075b6ed7156c2cd30df591bf3ae056ad2e28324fe668147c9c3fcb90c0a275e6e0a92137a94cea48f04dfb60100";
      const txid170 = "7feaf18b1a1717db138b8875a75924464b84c34cae6c85b061b6649bffac869d";

      parser = new MerkleRawProofParser(txid170, rawProof170);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot802368),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;

      const rawProof511 =
        "0000ff3f17dd318436d66875376a55a10962c3e7fe1e7c8f1a4e03000000000000000000eb150be4249d128ff5ca73e5bf1cbcbb12426ddb24143dadb6a5d999c1a518774486d3645b5f0517c4394600210a00000d0ecaad4f653b55531fcd9c9bf9bf8ef399dc76b71b7222d5016a43f37604ee348c0582b60bbca7726b450bf5b329fa272be6a6851d5f100090b29b7ccf1d946418a44a39f89e49bcf09148930fe7f99a05ac94f7538de2f8b435b107c615ee533a73b836b0b90d11a7a418a8de93737c1facd5764ece65905223cf13aa33c446c8066a72bf8490b0b3974ea2e7ce579205c850671c07f1da12a74625bac1b269f27b5bcff4d323b893954e1a9d0e0dd5fbcf91731f7dda21f87280056805d5242df2f0acf5ffc28ff0c00f3b22f0b3fc3e62053ea6c30d32e97325e903af9a154a16e1c4a8fc5d114d11a091c52209718b14b8644f1a8c801a6a1a2cbe6e1f79cb0a531bed0722529aa00f9041a0cc402b6ab9a0ec9bef0ad27da7c8557c7c31010028b4417f5cda9afff0d309dd5ec18cb872e1f403eb045ac2ebeffcb8bbfc31269a1723d450e37c989434823dc6f1b1f6958159204067b31dccbbbd956e8bd28769f43cf1870fefbee92e99b2ae0f150d4b99ba61fcb075b6ed7156c2cd30df591bf3ae056ad2e28324fe668147c9c3fcb90c0a275e6e0a92137a94cea48f04afaa2a00";
      const txid511 = "fcbbb8fcefebc25a04eb03f4e172b88cc15edd09d3f0ff9ada5c7f41b4280001";

      parser = new MerkleRawProofParser(txid511, rawProof511);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot802368),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;

      const rawProof1024 =
        "0000ff3f17dd318436d66875376a55a10962c3e7fe1e7c8f1a4e03000000000000000000eb150be4249d128ff5ca73e5bf1cbcbb12426ddb24143dadb6a5d999c1a518774486d3645b5f0517c4394600210a00000dc51758fb70d76e79fc1bbb3f28b8b852e7bb2575422157c0f3ea5bdaa026e69bffe7e082e8da9755e9a5a2810521f8d077c74d6a40d686eb4a6790c132e3e476554697df91ecf677ccf0d7f298b4008868e3d2f97a6e8761a1596bb5e6d62cf3c5bf98863291883c2c83c587a63c39b4018db19de4ad2878c5765d72760e30c7edf3c62fe2a624b5a21c87ab8e091a5b22e489630eca1a480dc8dd8ce8f9b3fe253c0076133f57ef58e3f3d702ba4895b8d03d57a89d2a7271bdc036dea72002a74d2b61aa9166e2e54d8dbe48e8ad2ce0535186cf5ba3028031dfc1fdc41eabd2f44661d96697f6bb06d3502d9e3de823502d7ae7ac8a1074df470163c3fb9b6c4729c569aa9549c78e99b54717a35347237a4d74db016c509aca8c434efc12b0ac7370b7f0a1435e5550bd193e6813d3739eb0084c082fafa804ccb77a948e05b6136e0ed28d7157e7db81f62d62cb88e6ae22ffe2d649b9f8fa861d5b22f3174488f809901215e22d8ee7b1378a1bc5e74818e51c8008601de736b3b83ffcdf591bf3ae056ad2e28324fe668147c9c3fcb90c0a275e6e0a92137a94cea48f04fb3f0000";
      const txid1024 = "76e4e332c190674aeb86d6406a4dc777d0f8210581a2a5e95597dae882e0e7ff";

      parser = new MerkleRawProofParser(txid1024, rawProof1024);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot802368),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;

      const rawProof1537 =
        "0000ff3f17dd318436d66875376a55a10962c3e7fe1e7c8f1a4e03000000000000000000eb150be4249d128ff5ca73e5bf1cbcbb12426ddb24143dadb6a5d999c1a518774486d3645b5f0517c4394600210a00000dc51758fb70d76e79fc1bbb3f28b8b852e7bb2575422157c0f3ea5bdaa026e69be8731bb79d64c8e08bbac17af638252b2e8b12ca780ed2d0f685aa04605f8a67d543fbcdb7d902eaad280ef13240d3608bddc5a01c996ca207077c3242428c2d62b9b4b431413ee238b8040f8f79c96620ac81a397913e77b1987b1ec0ac21645d2e9b58a12d9a849b24a14a021a03c76447e42d5ee09328bd53f9f2516c0cb16d6c19dd5d875887366e29276e336fabe0e586b8a3f94d649cf90102a75cf0477b73740ee2c1f2d35c23a17937ad5ca26bcc2c19720a398d87ed99e9f16e8c90b65ffbd9b823780fab35d184d50e5c305338e4f438286ee57ea0f9ae7719177939e0b46459e75a77006c12cd9122fa94dcca06d71aca01225afc33a5a7a48070bdfcb41642a1f24c3307019af5e53220b66f1a485b62fcff4c90b11c67ff8b4412fe1a1a9a843392fde0329d883e488d26560b3823b4e2131cc7976e764bf19b1732edecfddb62c0e4c77a43ec9f9594011718ca9f322c359301226e5fef8488df591bf3ae056ad2e28324fe668147c9c3fcb90c0a275e6e0a92137a94cea48f04ebbf0000";
      const txid1537 = "6421acc01e7b98b1773e9197a381ac2066c9798f0f04b838e23e4131b4b4b962";

      parser = new MerkleRawProofParser(txid1537, rawProof1537);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot802368),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;

      const rawProof1655 =
        "0000ff3f17dd318436d66875376a55a10962c3e7fe1e7c8f1a4e03000000000000000000eb150be4249d128ff5ca73e5bf1cbcbb12426ddb24143dadb6a5d999c1a518774486d3645b5f0517c4394600210a00000dc51758fb70d76e79fc1bbb3f28b8b852e7bb2575422157c0f3ea5bdaa026e69be8731bb79d64c8e08bbac17af638252b2e8b12ca780ed2d0f685aa04605f8a67b19e762a5f8cc0f54723ac125c67e8a7f6f51870550e0af34aa43c091e34e85ca6d8ae0255959f2fa42bf3cf784857a825dd9f9ac3c1f2f9407ff7bdfbc3efcb3d22b19dcc9ed86cb0d8c210febf0a4054c5ef02e70dafe157db349a5a32e58fd7869bf91764a4a181e87e1518b11c2721e9c45709029fec383e7bcf4e16128703eeb3493e94237ca38773f634ac28d8946b3f38bdddee63faf32b693b023bb79e546495cd301131cce64f4b72766a503c4bb79b8305d1d9e24ede70ca5d23113ada0e9bd3aaabc7f0258e5f67a25911c747a2b36a7f0a019baf79493f13963ab8e96f8427a30552974a4f5fe7332b7c03bb201c00fcd0e99863c8e21d052c7c12fe1a1a9a843392fde0329d883e488d26560b3823b4e2131cc7976e764bf19b1732edecfddb62c0e4c77a43ec9f9594011718ca9f322c359301226e5fef8488df591bf3ae056ad2e28324fe668147c9c3fcb90c0a275e6e0a92137a94cea48f04eb6a1500";
      const txid1655 = "3a96133f4979af9b010a7f6ab3a247c71159a2675f8e25f0c7abaad39b0eda3a";

      parser = new MerkleRawProofParser(txid1655, rawProof1655);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot802368),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;

      const rawProof2000 =
        "0000ff3f17dd318436d66875376a55a10962c3e7fe1e7c8f1a4e03000000000000000000eb150be4249d128ff5ca73e5bf1cbcbb12426ddb24143dadb6a5d999c1a518774486d3645b5f0517c4394600210a00000dc51758fb70d76e79fc1bbb3f28b8b852e7bb2575422157c0f3ea5bdaa026e69be8731bb79d64c8e08bbac17af638252b2e8b12ca780ed2d0f685aa04605f8a674e7384dc0fe361d642949ddef8992eb3377947171da1be797f4e076982b8fb157b55287cff79c3c8611476933ec2ab2f93e2d6ba3365c9d188ffafea174db07a8ff9c79b56e9c8d8015f3a0bd0ead652029038b363db7e91352a8caaac07c4b63b4b449a0c208f4ca7f6983363bce45f21b66a7d206930554f6956eb31a5b9e8e7915190d58883a8369fc5af88719e2d11267dd339ebf6965dc6dc5593458291a7a4c445d1fde01202432f3751e99ec1bacf1416f81a63c63deedc7f4779ee90116b157439ec2c6cc8458aac9d8c347de8efc5cc6e89b14041aedd7bd141b0692f48e029cae9d81127d32c3c59ab8b47859e4b5f687ed94c2056fa44aced373893722f0fb62ba4e5a01453f08809cb50f3fdd35816452e297e678fe46d48284d84e84f84a0ec19b78b6bc3eb12219cc61fa2ef057ed764561403916bfb8425addf591bf3ae056ad2e28324fe668147c9c3fcb90c0a275e6e0a92137a94cea48f04abda0700";
      const txid2000 = "9182459355dcc65d96f6eb39d37d26112d9e7188afc59f36a88388d5905191e7";

      parser = new MerkleRawProofParser(txid2000, rawProof2000);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot802368),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;

      const rawProofLast =
        "0000ff3f17dd318436d66875376a55a10962c3e7fe1e7c8f1a4e03000000000000000000eb150be4249d128ff5ca73e5bf1cbcbb12426ddb24143dadb6a5d999c1a518774486d3645b5f0517c4394600210a0000042c98d8b7f0246b9fcd1c4ed172f182786e67f49b2a3bf746fd5a5b07d83919f86096a4a871435b0d07e9bd9d746b3f71e90bfe41e3d041cdee73d4fe10ef419d904c1c046916d235c393e9cd3aa00f2e727453b88c125261ff25166aef845f2ea68a1c977fbc9bc924b7e10b99710ba4f94a41d10b72c303743d88b2e7b9fd9202edfd";
      const txidLast = "92fdb9e7b2883d7403c3720bd1414af9a40b71990be1b724c99bbc7f971c8aa6";

      parser = new MerkleRawProofParser(txidLast, rawProofLast);

      expect(
        await txMerkleProof.verify(
          parser.getSiblings(),
          reverseBytes(merkleRoot802368),
          parser.getTxidReversed(),
          parser.getTxIndex(),
        ),
      ).to.be.true;
    });

    it("should revert when a Merkle tree node is a valid bitcoin transaction", async () => {
      const tx64Bytes =
        "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff0404ffff00ffffffff0100f2052a010000000000000000";
      const insertedTx0 = addHexPrefix(tx64Bytes.slice(0, 64));
      const insertedTx1 = addHexPrefix(tx64Bytes.slice(64));

      const txid = sha256(sha256(addHexPrefix(tx64Bytes)));
      const merkleRoot = txid;

      expect(await txMerkleProof.verify([], merkleRoot, txid, 0)).to.be.true;

      let siblings = [insertedTx0];
      let leaf = insertedTx1;

      await expect(txMerkleProof.verify(siblings, merkleRoot, leaf, 1)).to.be.revertedWithCustomError(
        txMerkleProof,
        "InvalidMerkleNode",
      );

      siblings = [insertedTx1];
      leaf = insertedTx0;

      await expect(txMerkleProof.verify(siblings, merkleRoot, leaf, 0)).to.be.revertedWithCustomError(
        txMerkleProof,
        "InvalidMerkleNode",
      );
    });
  });
});
