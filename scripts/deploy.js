const hre = require("hardhat");

async function main() {
  const ParkPics = await hre.ethers.getContractFactory("ParkPics");
  const parkpics = await ParkPics.deploy();

  await parkpics.deployed();

  console.log("ParkPics deployed to:", parkpics.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });