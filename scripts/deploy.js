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

async function deployRunnerSoul() {
    const owner = await ethers.getSigner();
    const Soul = await ethers.getContractFactory("RunnerSoul", owner);
    const soul = await Soul.deploy(ethers.utils.parseEther("10"), 95e6); // 10 RTW , 95%
    await soul.deployed();

    console.log(`RunnerSoul deployed at { ${soul.address} }`);

    return soul;
}

async function deployRtwToken() {
    const owner = await ethers.getSigner();
    const Rtw = await ethers.getContractFactory("RtwToken", owner);
    const rtw = await Rtw.deploy();
    await rtw.deployed();

    console.log(`RtwToken deployed at { ${rtw.address} }`);

    return rtw;
}

async function deployRewardToken() {
    const owner = await ethers.getSigner();
    const RewardToken = await ethers.getContractFactory("RewardToken", owner);
    const rewardToken = await RewardToken.deploy();
    await rewardToken.deployed();

    console.log(`RewardToken deployed at { ${rewardToken.address} }`);

    return rewardToken;
}

async function deployPixelWar() {
    const owner = await ethers.getSigner();
    const PixelWar = await ethers.getContractFactory("PixelWar", owner);
    const pixelWar = await PixelWar.deploy(ethers.utils.parseEther("1")); // 1 RTW
    await pixelWar.deployed();

    console.log(`PixelWar deployed at { ${pixelWar.address} }`);

    return pixelWar;
}

async function deployTreasury() {
    const owner = await ethers.getSigner();
    const Treasury = await ethers.getContractFactory("Treasury", owner);
    const treasury = await Treasury.deploy();
    await treasury.deployed();

    console.log(`Treasury deployed at { ${treasury.address} }`);

    return treasury;
}

async function main() {
    factory = await deployFactory();
    soul = await deployRunnerSoul();
    rtw = await deployRtwToken();
    rewardToken = await deployRewardToken();
    pixelwar = await deployPixelWar();
    treasury = await deployTreasury();

    await factory.initialize(
        rtw.address, // IERC20 _rtw,
        soul.address, // IRunnerSoul _soulContract,
        config.LINK, // LinkTokenInterface _linkToken,
        config.VRF, // VRFCoordinatorV2Interface _vrfCoordinator,
        treasury.address // address _treasury
    );

    console.log("Factory initialized");

    await soul.initialize(
        rtw.address, //IERC20(_rtw);
        treasury.address, // _treasury;
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

    await pixelwar.initialize(
        soul.address // _soulContract;
    );

    console.log("PixelWar initialized");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
