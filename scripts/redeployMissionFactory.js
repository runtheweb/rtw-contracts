const hre = require("hardhat");
const ethers = hre.ethers;
const config = require("./contracts.json");

async function deployFactory() {
    const owner = await ethers.getSigner();
    const Factory = await ethers.getContractFactory("MissionFactory", owner);
    const factory = await Factory.deploy(1e7, 1e7); // 10% , 10%
    await factory.deployed();

    console.log(`MissionFactory deployed at { ${factory.address} }`);

    return factory;
}

async function main() {
    factory = await deployFactory();

    soul = await ethers.getContractAt("RunnerSoul", config.SOUL);
    rtw = await ethers.getContractAt("RtwToken", config.RTW);
    rewardToken = await ethers.getContractAt("RewardToken", config.REWARD);
    treasury = await ethers.getContractAt("Treasury", config.TREASURY);

    await factory.initialize(
        config.RTW, // IERC20 _rtw,
        config.SOUL, // IRunnerSoul _soulContract,
        config.LINK, // LinkTokenInterface _linkToken,
        config.VRF, // VRFCoordinatorV2Interface _vrfCoordinator,
        config.REWARD,
        config.TREASURY // address _treasury
    );

    console.log("Factory initialized");

    await soul.initialize(
        config.RTW, //IERC20(_rtw);
        config.TREASURY, // _treasury;
        factory.address // IMissionFactory(_factory);
    );

    console.log("Soul initialized");

    await rtw.initialize(
        factory.address // _factory;
    );

    console.log("RTW initialized");

    await rewardToken.initialize(
        factory.address // _factory;
    );

    console.log("RewardToken initialized");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
