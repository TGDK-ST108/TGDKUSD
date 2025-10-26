// deploy_TGDKUSD.cjs
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("🔗 Deployer:", deployer.address);

  const reserveAddr = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"; // USDC mainnet
  const Token = await hre.ethers.getContractFactory("TGDKUSD");
  const token = await Token.deploy(reserveAddr);
  await token.waitForDeployment?.();
  console.log("✅ TGDK-USD deployed to:", await token.getAddress?.() || token.address);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
