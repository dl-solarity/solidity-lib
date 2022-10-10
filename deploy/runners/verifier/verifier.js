class Verifier {
  async verify(...contractsWithArgs) {
    hre.config.contractSizer.runOnCompile = false;

    for (let i = 0; i < contractsWithArgs.length; i++) {
      const contract = contractsWithArgs[i][0];
      const fileName = contract.constructor._hArtifact.sourceName;
      const contractName = contract.constructor._hArtifact.contractName;
      const args = contractsWithArgs[i].slice(1);

      try {
        await hre.run("verify:verify", {
          address: contract.address,
          constructorArguments: args,
          contract: fileName + ":" + contractName,
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
