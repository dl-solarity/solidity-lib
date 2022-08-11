class Verifier {
  async verify(...contractsWithArgs) {
    hre.config.contractSizer.runOnCompile = false;

    for (let i = 0; i < contractsWithArgs.length; i++) {
      const contractAddr = contractsWithArgs[i][0].address;
      const args = contractsWithArgs[i].slice(1);

      try {
        await hre.run("verify:verify", {
          address: contractAddr,
          constructorArguments: args,
        });

        await hre.run("compile", {
          quiet: true,
        });
      } catch (e) {
        console.log(e.message);
      }
    }
  }
}

module.exports = Verifier;
