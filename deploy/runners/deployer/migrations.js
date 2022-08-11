const fs = require("fs");
const path = require("path");
const Deployer = require("./deployer");

class Migrations {
  getMigrationFiles() {
    const migrationsDir = "./deploy/migrations/";

    const directoryContents = fs.readdirSync(`${migrationsDir}`);
    let files = directoryContents
      .filter((file) => !isNaN(parseInt(path.basename(file))))
      .filter((file) => fs.statSync(migrationsDir + file).isFile());

    if (files.length === 0) return [];

    files = files.sort((a, b) => {
      if (a.number > b.number) {
        return 1;
      } else if (a.number < b.number) {
        return -1;
      }

      return 0;
    });

    return files;
  }

  isVerify() {
    return process.env.VERIFY == "true";
  }

  async migrate() {
    try {
      const migrationFiles = this.getMigrationFiles();
      const verify = this.isVerify();
      const deployer = new Deployer();

      if (verify) {
        console.log("\nAUTO VERIFICATION IS ON");
      }

      await deployer.startMigration(verify);

      console.log(migrationFiles);

      for (let i = 0; i < migrationFiles.length; i++) {
        const func = require("../../migrations/" + migrationFiles[i]);

        await func(deployer);
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
