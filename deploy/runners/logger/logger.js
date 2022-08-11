function logTransaction(tx, name) {
  console.log(`Transaction ${name}: Gas used ${tx.receipt.gasUsed}, Hash ${tx.tx}\n`);
}

function logContracts(...contracts) {
  let table = [];

  for (let i = 0; i < contracts.length; i++) {
    table.push({ "Proxy Contract": contracts[i][0], Address: contracts[i][1] });
  }

  console.table(table);

  console.log();
}

module.exports = {
  logTransaction,
  logContracts,
};
