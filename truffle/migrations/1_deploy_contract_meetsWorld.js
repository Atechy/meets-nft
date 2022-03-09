var MeetsWorld = artifacts.require('./MeetsWorld');
require('dotenv').config();

module.exports = async function (deployer) {

  await deployer.deploy(
    MeetsWorld,
    process.env.BUILDER,
    process.env.MARKETINGA,
    process.env.MARKETINGB
    );
  await MeetsWorld.deployed();
};
