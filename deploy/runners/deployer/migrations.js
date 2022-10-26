const fs = require("fs");
const path = require("path");
const Deployer = require("../deployer/deployer");

class Migrations {
  getMigrationFiles() {
    const migrationsDir = "./deploy/migrations/";
    const directoryContents = fs.readdirSync(migrationsDir);

    let files = directoryContents
      .filter((file) => !isNaN(parseInt(path.basename(file))))
      .filter((file) => fs.statSync(migrationsDir + file).isFile())
      .sort((a, b) => {
        return parseInt(path.basename(a)) - parseInt(path.basename(b));
      });

    return files;
  }

  isVerify() {
    return process.env.VERIFY == "true";
  }

  confirmations() {
    return process.env.CONFIRMATIONS;
  }

  getParams() {
    const verify = this.isVerify();
    let confirmations = 0;

    if (verify) {
      console.log("\nAUTO VERIFICATION IS ON");

      confirmations = 5;
    }

    if (this.confirmations() != undefined) {
      confirmations = this.confirmations();
    }

    return [verify, confirmations];
  }

  async migrate() {
    try {
      const migrationFiles = this.getMigrationFiles();
      const deployer = new Deployer();

      await deployer.startMigration(...this.getParams());

      console.log(migrationFiles);

      for (let i = 0; i < migrationFiles.length; i++) {
        const migration = require("../../migrations/" + migrationFiles[i]);

        await migration(deployer);
      }

      await deployer.finishMigration();

      process.exit(0);
    } catch (e) {
      console.log(e.message);
      process.exit(1);
    }
  }
}

let migrations = new Migrations();

migrations.migrate().then();
