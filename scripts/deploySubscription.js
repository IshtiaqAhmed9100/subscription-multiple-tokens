const hre = require("hardhat");
const { run } = require("hardhat");
async function verify(address, constructorArguments) {
  console.log(
    `verify  ${address} with arguments ${constructorArguments.join(",")}`
  );
  await run("verify:verify", {
    address,
    constructorArguments,
  });
}
async function main() {
  const fundsWalletAddress = "0x5d63cE81FAbaCf586A8fd4039Db08B59BE909D5b";
  const signerAddress = "0x12eF0F1C99D8FD50fFd37cCd12B09Ef7f1213269";
  const owner = "0x12ef0f1c99d8fd50ffd37ccd12b09ef7f1213269";
  const subscriptionFeeInit = 400000000;

  const Subscription = await hre.ethers.deployContract("Subscription", [
    fundsWalletAddress,
    signerAddress,
    owner,
    subscriptionFeeInit,
  ]);

  console.log("Deploying Subscription...");
  await Subscription.waitForDeployment();
  console.log("Subscription deployed to:", Subscription.target);

  await new Promise((resolve) => setTimeout(resolve, 20000));
  verify(Subscription.target, [
    fundsWalletAddress,
    signerAddress,
    owner,
    subscriptionFeeInit,
  ]);
}
main();
