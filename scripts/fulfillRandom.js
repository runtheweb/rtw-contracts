const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
    MISSION_ADDRESS = "0x5777898321969A450808c94Ff24985763C3F8665";
    RANDOM_WORDS = [42];
    mission = await ethers.getContractAt("Mission", MISSION_ADDRESS);
    await mission.testFulfillRandomWords(RANDOM_WORDS);
    console.log("Random fulfilled");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
