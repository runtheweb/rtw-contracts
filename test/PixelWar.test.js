const { expect } = require("chai");
const { ethers, userConfig } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

async function deployFactory() {
    const owner = await ethers.getSigner();
    const Factory = await ethers.getContractFactory("MissionFactory", owner);
    const factory = await Factory.deploy(1e7, 1e7); // 10% , 10%
    await factory.deployed();
    return factory;
}

async function deployRunnerSoul() {
    const owner = await ethers.getSigner();
    const Soul = await ethers.getContractFactory("RunnerSoul", owner);
    const soul = await Soul.deploy(ethers.utils.parseEther("10"), 95e6); // 10 RTW , 95%
    await soul.deployed();
    return soul;
}

async function deployRtwToken() {
    const owner = await ethers.getSigner();
    const Rtw = await ethers.getContractFactory("RtwToken", owner);
    const rtw = await Rtw.deploy();
    await rtw.deployed();
    return rtw;
}

async function deployRewardToken() {
    const owner = await ethers.getSigner();
    const RewardToken = await ethers.getContractFactory("RewardToken", owner);
    const rewardToken = await RewardToken.deploy();
    await rewardToken.deployed();
    return rewardToken;
}

async function deployPixelWar() {
    const owner = await ethers.getSigner();
    const PixelWar = await ethers.getContractFactory("PixelWar", owner);
    const pixelWar = await PixelWar.deploy(ethers.utils.parseEther("1")); // 1 RTW
    await pixelWar.deployed();
    return pixelWar;
}

async function deployTreasury() {
    const owner = await ethers.getSigner();
    const Treasury = await ethers.getContractFactory("Treasury", owner);
    const treasury = await Treasury.deploy();
    await treasury.deployed();
    return treasury;
}

async function deployMockERC20(name, symbol) {
    const owner = await ethers.getSigner();
    const Mock = await ethers.getContractFactory("MockERC20", owner);
    const mock = await Mock.deploy(name, symbol);
    await mock.deployed();
    return mock;
}

async function deployMockVrf() {
    const owner = await ethers.getSigner();
    const Mock = await ethers.getContractFactory("VRFCoordinatorV2Mock", owner);
    const mock = await Mock.deploy(100000, 100000);
    await mock.deployed();
    return mock;
}

async function deployMockLink() {
    const owner = await ethers.getSigner();
    const Mock = await ethers.getContractFactory("MockLink", owner);
    const mock = await Mock.deploy();
    await mock.deployed();
    return mock;
}

describe("Mission", function () {
    let deployer, alice, bob, carol;
    let factory;

    const ETH = ethers.utils.parseEther("1.0");

    beforeEach(async () => {
        [deployer, alice, bob, carol] = await ethers.getSigners();

        factory = await deployFactory();
        soul = await deployRunnerSoul();
        rtw = await deployRtwToken();
        rewardToken = await deployRewardToken();
        pixelwar = await deployPixelWar();
        treasury = await deployTreasury();

        usdt = await deployMockERC20("USDT", "USDT");

        link = await deployMockLink();
        vrf = await deployMockVrf();

        await factory.initialize(
            rtw.address, // IERC20 _rtw,
            soul.address, // IRunnerSoul _soulContract,
            link.address, // LinkTokenInterface _linkToken,
            vrf.address, // VRFCoordinatorV2Interface _vrfCoordinator,
            rewardToken.address, // IRewardToken _rewardToken
            treasury.address // address _treasury
        );

        await soul.initialize(
            rtw.address, //IERC20(_rtw);
            treasury.address, // _treasury;
            factory.address // IMissionFactory(_factory);
        );

        await rtw.initialize(
            factory.address // _factory;
        );

        await rewardToken.initialize(
            factory.address // _factory;
        );

        await pixelwar.initialize(
            soul.address // _soulContract;
        );

        await rtw.mintTest(ETH.mul(100));
        await rtw.approve(soul.address, ETH.mul(10));
        await soul.mintSoul();
    });

    describe("Basic tests", function () {
        it("Should color and clear pixels", async function () {
            await pixelwar.colorPixel(0, 0, 0x123456);
            expect(await pixelwar.totalPixels()).to.be.equal(1);
            expect(await pixelwar.userReputation(deployer.address)).to.be.equal(ETH.mul(10));
            expect(await pixelwar.isColorable(0, 0)).to.be.equal(false);
            expect(await pixelwar.isClearable(0, 0)).to.be.equal(true);
            expect(await pixelwar.connect(alice).isClearable(0, 0)).to.be.equal(false);
            expect(await pixelwar.availablePixels(deployer.address)).to.be.equal(9);
            expect(await pixelwar.totalUserPixels(deployer.address)).to.be.equal(1);
            await pixelwar.clearPixel(0, 0);
            expect(await pixelwar.availablePixels(deployer.address)).to.be.equal(10);
            expect(await pixelwar.totalUserPixels(deployer.address)).to.be.equal(0);
        });
    });
});
