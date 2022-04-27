const MeetsWorld = artifacts.require('./MeetsWorld');
const path = require('path');
const filePath = path.join(__dirname, '../../.env');
require('dotenv').config({path:filePath});

module.exports = async function (deployer) {

  await deployer.deploy(
    MeetsWorld,
    process.env.BUILDER,
    process.env.MARKETINGA,
    process.env.MARKETINGB,
    process.env.VerificationAdmin
    );
  await MeetsWorld.deployed();
};
