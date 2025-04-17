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

const fundsWalletAddress = "0x5d63cE81FAbaCf586A8fd4039Db08B59BE909D5b";
const signerAddress = "0x12eF0F1C99D8FD50fFd37cCd12B09Ef7f1213269";
const owner = "0x12ef0f1c99d8fd50ffd37ccd12b09ef7f1213269";
const subscriptionV1Address = "0xDd8B68ad2fF84C97F5198e9c5512171F1f779b42";
const subscriptionFeeInit = 400000000;

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
