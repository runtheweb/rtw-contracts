const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
    MISSION_ADDRESS = "0x0403692312cAD3b9692e54eFacBFf459ff6837a1";
    RANDOM_WORDS = [42];
    mission = await ethers.getContractAt("Mission", MISSION_ADDRESS);
    await mission.testFulfillRandomWords(RANDOM_WORDS);
    console.log("Random fulfilled");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
