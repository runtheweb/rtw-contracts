const { expect } = require("chai");
const { ethers } = require("hardhat");
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
        await usdt.mint(deployer.address, ETH.mul(1000));
        await rtw.approve(factory.address, ETH.mul(100));
        await usdt.approve(factory.address, ETH.mul(1000));
        await link.mint(factory.address, ETH.mul(100));

        await factory.createSubscription();
        await vrf.fundSubscription(factory.subscriptionId(), ETH.mul(100));

        tx = await factory.createMission(
            "test codex", //string memory _codex,
            ETH.mul(4), //uint256 _totalRewardAmount,
            ETH.mul(20), //uint256 _totalOperationAmount,
            ETH.mul(40), //uint256 _minTotalCollateralPledge,
            usdt.address, //address _operationToken,
            2, //uint32 _numberOfCouriers,
            2, //uint32 _numberOfArbiters,
            3600, //uint32 _executionTime,
            3600 //uint32 _ratingTime
        );
        rx = await tx.wait();

        addr = ethers.utils.defaultAbiCoder.decode(["address"], rx.logs[7].topics[1])[0];
        mission = await ethers.getContractAt("Mission", addr);

        await rtw.approve(soul.address, ETH.mul(10));
        // console.log(await soul.getReputation(deployer.address));

        await soul.mintSoul();
        // console.log(await soul.getReputation(deployer.address));

        await rtw.approve(mission.address, ETH.mul(20));

        await rtw.connect(alice).mintTest(ETH.mul(100));
        await rtw.connect(bob).mintTest(ETH.mul(100));
        await rtw.connect(carol).mintTest(ETH.mul(100));
        await rtw.connect(alice).approve(soul.address, ETH.mul(10));
        await rtw.connect(bob).approve(soul.address, ETH.mul(10));
        await rtw.connect(carol).approve(soul.address, ETH.mul(10));
        await soul.connect(alice).mintSoul();
        await soul.connect(bob).mintSoul();
        await soul.connect(carol).mintSoul();
        await rtw.connect(alice).approve(mission.address, ETH.mul(20));
        await rtw.connect(bob).approve(mission.address, ETH.mul(20));
        await rtw.connect(carol).approve(mission.address, ETH.mul(20));
    });

    describe("Basic tests", function () {
        it("Should join mission", async function () {
            balanceRtw = await rtw.balanceOf(deployer.address);

            await mission.joinMission(ETH.mul(15), ETH.mul(5));

            expect(await soul.getReputation(deployer.address)).to.be.equal(ETH.mul(5));
            expect(await rtw.balanceOf(deployer.address)).to.be.equal(balanceRtw.sub(ETH.mul(15)));
            expect(await mission.totalRunners()).to.be.equal(1);
            expect((await mission.positions(deployer.address))[0]).to.be.equal(1);
            expect((await mission.positions(deployer.address))[1]).to.be.equal(ETH.mul(15));
            expect((await mission.positions(deployer.address))[2]).to.be.equal(ETH.mul(5));
        });

        it("Should leave mission", async function () {
            balanceRtw = await rtw.balanceOf(deployer.address);
            await rtw.approve(mission.address, ETH.mul(15));
            await mission.joinMission(ETH.mul(15), ETH.mul(5));
            await mission.leaveMission();
            expect(await soul.getReputation(deployer.address)).to.be.equal(ETH.mul(10));
            expect(await rtw.balanceOf(deployer.address)).to.be.equal(balanceRtw);
            expect(await mission.totalRunners()).to.be.equal(0);
            expect((await mission.positions(deployer.address))[0]).to.be.equal(0);
        });

        it("Should init and start mission", async function () {
            await mission.joinMission(ETH.mul(15), ETH.mul(5));
            await mission.connect(alice).joinMission(ETH.mul(15), ETH.mul(5));
            await mission.connect(bob).joinMission(ETH.mul(15), ETH.mul(5));
            await expect(mission.initMission()).to.be.revertedWith("Insufficient runners");
            await mission.connect(carol).joinMission(ETH.mul(15), ETH.mul(5));

            await mission.initMission();
            await expect(mission.leaveMission()).to.be.revertedWith(
                "Cannot withdraw until mission end"
            );
            await expect(mission.startMission()).to.be.revertedWith(
                "Initialization is not completed"
            );
            await vrf.fulfillRandomWords(mission.lastRequestId(), mission.address);
            expect((await mission.lastRequest())[0]).to.be.equal(true);
            expect((await mission.positions(alice.address))[3]).to.be.equal(0);

            await mission.startMission();

            expect((await mission.positions(alice.address))[3]).to.be.equal(1);
            expect((await mission.positions(bob.address))[3]).to.be.equal(1);
            expect((await mission.positions(deployer.address))[3]).to.be.equal(2);
            expect((await mission.positions(carol.address))[3]).to.be.equal(2);
        });
        it("Should take operation tokens", async function () {
            await mission.joinMission(ETH.mul(15), ETH.mul(5));
            await mission.connect(alice).joinMission(ETH.mul(15), ETH.mul(5));
            await mission.connect(bob).joinMission(ETH.mul(15), ETH.mul(5));
            await mission.connect(carol).joinMission(ETH.mul(15), ETH.mul(5));
            await mission.initMission();
            await vrf.fulfillRandomWords(mission.lastRequestId(), mission.address);
            await mission.startMission();
            // couriers : alice , bob
            // arbiters : deployer, carol
            await mission.connect(alice).takeOperationTokens();
            await mission.connect(bob).takeOperationTokens();
            expect(await usdt.balanceOf(alice.address)).to.be.equal(ETH.mul(10));
            expect(await usdt.balanceOf(bob.address)).to.be.equal(ETH.mul(10));
            await mission.connect(alice).pushProof("proof text");
            await expect(mission.rateCouriers([true, false])).to.be.revertedWith(
                "Arbiters time has not come yet"
            );
        });
        it("Should rate couriers good", async function () {
            await mission.joinMission(ETH.mul(15), ETH.mul(5));
            await mission.connect(alice).joinMission(ETH.mul(15), ETH.mul(5));
            await mission.connect(bob).joinMission(ETH.mul(15), ETH.mul(5));
            await mission.connect(carol).joinMission(ETH.mul(15), ETH.mul(5));
            await mission.initMission();
            await vrf.fulfillRandomWords(mission.lastRequestId(), mission.address);
            await mission.startMission();
            // couriers : alice , bob
            // arbiters : deployer, carol
            await mission.connect(alice).takeOperationTokens();
            await mission.connect(bob).takeOperationTokens();
            await mission.connect(alice).pushProof("proof text alice");
            await time.increase(3600);
            await expect(mission.connect(bob).pushProof("proof text bob")).to.be.revertedWith(
                "Courier time is over"
            );

            await mission.rateCouriers([true, true]); // will be punished
            await mission.connect(carol).rateCouriers([true, false]); // will be rewarded
            await time.increase(3600);
            await mission.endMission();
            expect(await mission.runnerResult(deployer.address)).to.be.equal(false);
            expect(await mission.runnerResult(alice.address)).to.be.equal(true);
            expect(await mission.runnerResult(bob.address)).to.be.equal(false);
            expect(await mission.runnerResult(carol.address)).to.be.equal(true);
        });

        it("Should properly withdraw collateral and get reward token", async function () {
            await mission.joinMission(ETH.mul(15), ETH.mul(5));
            await mission.connect(alice).joinMission(ETH.mul(15), ETH.mul(5));
            await mission.connect(bob).joinMission(ETH.mul(15), ETH.mul(5));
            await mission.connect(carol).joinMission(ETH.mul(15), ETH.mul(5));
            await mission.initMission();
            await vrf.fulfillRandomWords(mission.lastRequestId(), mission.address);
            await mission.startMission();
            // couriers : alice , bob
            // arbiters : deployer, carol
            await mission.connect(alice).takeOperationTokens();
            await mission.connect(bob).takeOperationTokens();
            await mission.connect(alice).pushProof("proof text alice");
            await time.increase(3600);
            await mission.rateCouriers([true, true]); // will be punished
            await mission.connect(carol).rateCouriers([true, false]); // will be rewarded
            await time.increase(3600);
            balanceBefore = await rtw.balanceOf(deployer.address);
            await mission.connect(alice).endMission();
            expect(await rtw.balanceOf(deployer.address)).to.be.equal(
                balanceBefore.add(ETH.mul(18)) // receive collateral of looser courier
            );

            await expect(mission.withdrawCollateral()).to.be.revertedWith(
                "Loosers cannot withdraw"
            );
            await expect(mission.connect(bob).withdrawCollateral()).to.be.revertedWith(
                "Loosers cannot withdraw"
            );

            tokenId = await rewardToken.getIdByMissionAddress(mission.address);
            await mission.connect(alice).withdrawCollateral();
            expect(await soul.getReputation(alice.address)).to.be.equal(ETH.mul(105).div(10));
            expect(await rewardToken.balanceOf(alice.address, tokenId)).to.be.equal(1);

            await rewardToken.connect(carol).mintRewardToken(carol.address, mission.address);
            await mission.connect(carol).withdrawCollateral();
            expect(await soul.getReputation(carol.address)).to.be.equal(ETH.mul(105).div(10));
            expect(await rewardToken.balanceOf(carol.address, tokenId)).to.be.equal(1);
        });
    });
});
