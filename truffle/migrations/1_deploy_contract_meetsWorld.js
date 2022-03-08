var MeetsWorld = artifacts.require('./MeetsWorld');
require('dotenv').config();

module.exports = async function (deployer) {

  await deployer.deploy(MeetsWorld,process.env.Sec_Owner_address);
  await MeetsWorld.deployed();
};
