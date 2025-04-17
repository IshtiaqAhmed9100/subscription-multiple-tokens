const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");

const { network, run } = require("hardhat");

async function verify(address, constructorArguments) {
  console.log(
    `verify  ${address} with arguments ${constructorArguments.join(",")}`
  );
  await run("verify:verify", {
    address,
    constructorArguments,
  });
}

const fundsWalletAddress = "0x4d13fE9571AaacAd18168F0A21417917b2BcFB55";
const signerAddress = "0xBEA27f00dd8a062F614d8C7fF8FA0f61023202CE";
const owner = "0x850ea2E1745EDD7F567A9FCa2a53f05A13D1AFF5";
const subscriptionV1Address = "0x92831c35EB46D8CA2F520cba1111D0Ae9A9a8A4C";
const subscriptionFeeInit = 200000000;

async function main() {
  const Subscription = await ethers.getContractFactory("Subscription");

  const instance = await upgrades.deployProxy(
    Subscription,
    [
      fundsWalletAddress,
      signerAddress,
      owner,
      subscriptionV1Address,
      subscriptionFeeInit,
    ],

    {
      initializer: "initialize",
      kind: "uups",
    }
  );

  await instance.waitForDeployment();

  console.log("Subscription deployed to:", instance.target);

  await new Promise((resolve) => setTimeout(resolve, 20000));
  verify(instance.target, []);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
