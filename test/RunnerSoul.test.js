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
    });

    describe("Basic tests", function () {
        it("Should mint and burn soul", async function () {
            await rtw.mintTest(ETH.mul(100));
            await rtw.approve(soul.address, ETH.mul(10));
            await soul.mintSoul();
            expect((await soul.souls(deployer.address))[0]).to.be.equal(ETH.mul(10));
            expect((await soul.souls(deployer.address))[1]).to.be.equal(ETH.mul(10));
            expect(await rtw.balanceOf(deployer.address)).to.be.equal(ETH.mul(90));
            expect(await soul.balanceOf(deployer.address)).to.be.equal(1);
            await expect(soul.mintSoul()).to.be.revertedWith("Courier soul already minted");
            await soul.burnSoul();
            expect((await soul.souls(deployer.address))[0]).to.be.equal(ETH.mul(0));
            expect((await soul.souls(deployer.address))[1]).to.be.equal(ETH.mul(0));
            expect(await rtw.balanceOf(deployer.address)).to.be.equal(ETH.mul(100));
            expect(await soul.balanceOf(deployer.address)).to.be.equal(0);
        });
    });
});
