import { ethers } from "hardhat";
import { expect } from "chai";
import { Reverter } from "@/test/helpers/reverter";

import { RSASSAPSSMock } from "@ethers-v6";
import { randomBytes } from "ethers";

describe("RSASSAPSS", () => {
  const reverter = new Reverter();

  let rsassapss: RSASSAPSSMock;

  before(async () => {
    const RSASSAPSSMock = await ethers.getContractFactory("RSASSAPSSMock");

    rsassapss = await RSASSAPSSMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("SHA256", () => {
    const message =
      "0x308203c3a003020102020874442b6b708ef7a2304106092a864886f70d01010a3034a00f300d06096086480165030402010500a11c301a06092a864886f70d010108300d06096086480165030402010500a203020120302f310b3009060355040613025048310c300a060355040a0c034446413112301006035504030c09435343413031303037301e170d3232313231323136303030305a170d3333303430313135353935395a302d310b3009060355040613025048310c300a060355040a13034446413110300e060355040313074453303131313330820122300d06092a864886f70d01010105000382010f003082010a0282010100ab630b320a41ecf8886a904ab50fabcfad658f5af8a9f8aaecefe0dc5e2ea99eba3deccba3f58885f8574fe0ad5c889763afc2b68e66b5928403d508724ad1e7fd05c573c053e04660fd31128cff2e2f574ec92430202f5dafa6df66b46fb16ece1372424d3aa3b975428c59f18fe1f32e6c328b64f58f95e05684dfff2d21a85cb73bcb32ac172c8f782fa2ea942118379833bec37cab64de493ddae79014ed0e6fcaa2ca4cdc3bdb0442ba550cde8355194c3c3934b2d8bfa513fcf5788c0569e0527cd20daa5e8e114204661a3d1f21650d01703e7a112602cf8fbefbc329afc18d3d49a68b60e5c89c5152ad6e7f0480b0e4157b26640c569ae477e04f190203010001a38201c7308201c3300e0603551d0f0101ff040403020780301d0603551d0e04160414363257ff5b20debaa6e26c257d3ebb4fa1e7bcf5305e0603551d23045730558014a1436db84f1c134e49b387da56cee801102d4f73a133a431302f310b3009060355040613025048310c300a060355040a0c034446413112301006035504030c0943534341303130303782086b8a5f2f46fa934b302b0603551d1004243022800f32303232313231323136303030305a810f32303233303430313135353935395a30390603551d1104323030811c70617373706f72742e6469726563746f72406466612e676f762e7068a410300e310c300a06035504070c0350484c30390603551d1204323030811c70617373706f72742e6469726563746f72406466612e676f762e7068a410300e310c300a06035504070c0350484c306d0603551d1f046630643030a02ea02c862a68747470733a2f2f706b64646f776e6c6f6164312e6963616f2e696e742f43524c732f50484c2e63726c3030a02ea02c862a68747470733a2f2f706b64646f776e6c6f6164322e6963616f2e696e742f43524c732f50484c2e63726c3020060767810801010602041530131301501302504f130250441302505213025053";
    const s =
      "0x875ef62f6832599f41b50ca51a478c92ff47b61f2090157f64b425b1e1ad5612e6abb7d5808d9be5f0eaaa16d2b516ef161534c78d542ffd659107535c2bab643163fb9af27a50389792508d1cdbda347a103404c5e08d2d97c7935994631d42fe7e0caa892dc3ec39d3ac94dbccb3cd0870b21b9c836feed5bc32e9ec6830392bdade1fc9b5280fbaa2ceaa78d9524af3d015cbaf07eebc84a9caec81a4407452573a101b79772056193d207a8398690ed0dd0cc5a6410fd844d313c50934d6e1d556f8e7b39b12525f3cd766c9342fbd892e40408b0c232d888da11fc64d0f09db70971d395d7a1d2aacfe9da78e3c46ce43b3ce5b9fc1e6a90c065cdafa2e8a117d63c00cf9f54e3a3313789f03dd7efc76641c2cf5068ca4512c82fa6c62f6bd36b12523dc46f444b8312d2f6e6ec22cd10eddb19220d9b8ba4cc442dd836335482c6309d56e87492d2fdaefdb7b5ede566ed43eb87955451225846ce2535b803a9ca79034cc3aa41307cc57f0962cb8b2c3b99a5c87150387f7d8de6a18f6a838404c4aa5bb279378fb285c096d4c2664c700ac4e3c0cb44f920928e764dd4b10f22d3cb5bdfac78066b1b0a5ae75528e447b262510d41150a94ab0f645cc61ae99a3719bd29cf3901dde6de7cc162051f34c642a0f7854ef00d4143d755ad72bc71371c3a8dedb94118272f37f853bd171743b0c7a9a8cb96095476c9c";
    const e = ethers.toBeHex(65537n);
    const n =
      "0xd24081be6cc14fe3fb4b35ab6df1a7f28f373017ef15a26b67ff2dd04773a3ef8942b7ba5f2f91aea469fe757e2e3362a907610b441f3610f528b1f39739a132c4bebc26c37d25b6d12481336fecddfc6bdcd011be4f2912ff0663cb70d9938280813dd3f32f2e6fef184881f784bbd2fd2d165b169d8594c45d832dbaebfdcb532d6542b57413825df5164b577dcdc248dfc4a8b071eb0bef021128e9172b77a18a5a6b00ebc0e07af0a9df6592684805a4ba0db00dddaabf793641ec0da51aecc6160acd56a0194d1161271b8feaaf0ae851ae65f1464c79607bbb237de3dbd0a299e9cda846c362976108d10555b57866a56c87c6a5d92d1888d6260fa90459afb14688b8a53921d2d477d1677518956412e01eb2592b27ad62a3d3a50777c4bee3f348b4788bb7bbd38d6bd902968a7b3640d75f98b78824ee9462e1b2d405b8c1ce7d7dbef479c2979553790b7d7fa8a6f05dad4cf95b92a218b410eb5b9df712d099b6952a07f122d21e95b934e9a765e758397b191fd01c0c4ae669039a0d7003308ab78d03809752bb7b676c3f3bbd9ac4b8cf0162efb50e01c52e3a97fed31d1e73f12b3da7b4df87fd7e93f70f92dc154d0bcef5a39c9631b2b50c7c7b91f4a63d4e3d487c37fc63bbdf87b71cad5581409661d15f77ff738a4d53d23424d999490607ebfd8293b2fb5c269cd8a19477ca88f6f7cb1abe00fb16c9";

    it("should verify signature", async () => {
      expect(await rsassapss.verifySha256(message, s, e, n)).to.be.true;
    });

    it("should not verify invalid signature", async () => {
      const message = "0x0123456789";

      expect(await rsassapss.verifySha256(message, s, e, n)).to.be.false;
    });

    it("should not verify if s, e or n parameters length is equal to zero", async () => {
      const zeroParameter = "0x";

      expect(await rsassapss.verifySha256(message, zeroParameter, e, n)).to.be.false;
      expect(await rsassapss.verifySha256(message, s, zeroParameter, n)).to.be.false;
      expect(await rsassapss.verifySha256(message, s, e, zeroParameter)).to.be.false;
    });

    it("should not verify if signature_[sigBytes_ - 1] != hex`BC`", async () => {
      const zeroParameter =
        "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

      expect(await rsassapss.verifySha256(message, zeroParameter, e, n)).to.be.false;
    });

    it("should not verify if sigBytes_ < hashLength_ + saltLength_ + 2", async () => {
      const n = "0x" + Buffer.from(randomBytes(64)).toString("hex");

      expect(await rsassapss.verifySha256(message, s, e, n)).to.be.false;
    });
  });
});
