const { expect } = require("chai");
const { ethers } = require("hardhat");

async function deployFactory() {
    const owner = await ethers.getSigner();
    const Factory = await ethers.getContractFactory("MissionFactory", owner);
    const factory = await Factory.deploy(ETH.div(10), ETH.div(10)); // 10% , 10%
    await factory.deployed();
    return factory;
}

async function deployRunnerSoul() {
    const owner = await ethers.getSigner();
    const Soul = await ethers.getContractFactory("RunnerSoul", owner);
    const soul = await Soul.deploy(ETH.mul(10), ETH.div(100).mul(95)); // 10 RTW , 95%
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
    const pixelWar = await PixelWar.deploy();
    await pixelWar.deployed();
    return pixelWar;
}

describe("Mission", function () {
    let deployer, alice, bob, carol;
    let factory, mission;

    const ETH = ethers.utils.parseEther("1.0");

    before(async () => {
        factory = deployFactory();
    });

    beforeEach(async () => {
        [deployer, alice, bob, carol] = await ethers.getSigners();

        await synter.initialize(
            rUsd.address, // _rUsdAddress,
            synergy.address, // _synergyAddress,
            loan.address, // _loanAddress,
            oracle.address, // _oracle,
            treasury.address // _treasury
        );

        await synergy.initialize(
            rUsd.address, // _rUsd,
            wEth.address, // _wEth, !!! todo
            raw.address, // _raw,
            synter.address, // _synter,
            oracle.address, // _oracle,
            treasury.address, // _treasury,
            loan.address, // _loan,
            insurance.address // _insurance
        );

        await rUsd.initialize(
            synter.address // _synter
        );
        await oracle.initialize(
            rUsd.address // _rUsd
        );

        await insurance.initialize(
            rUsd.address, // _rUsd
            raw.address, // _raw
            synergy.address, // _synergy
            oracle.address // _oracle
        );

        await loan.initialize(
            rUsd.address, // ISynt(_rUsd);
            synter.address, // ISynter(_synter);
            treasury.address, // ITreasury(_treasury);
            oracle.address // IOracle(_oracle);
        );

        await raw.initialize(
            insurance.address // _insurance
        );

        // set datafeed for RAW with price 10$
        dataFeed = await deployMockDataFeed("RAW", ethers.utils.parseEther("10"));
        await oracle.changeFeed(raw.address, dataFeed.address);

        // set datafeed for wETH with price 1600$
        dataFeed = await deployMockDataFeed("WETH", ethers.utils.parseEther("1600"));
        await oracle.changeFeed(wEth.address, dataFeed.address);
    });

    describe("Basic tests", function () {
        it("Should substract RAW", async function () {
            await raw.mintTest(ETH.mul(1000));
            await raw.approve(insurance.address, ETH.mul(1000));
            await insurance.stakeRaw(2628000, ETH.mul(1000));

            expect(await raw.balanceOf(deployer.address)).to.be.equal(0);
            expect(await raw.balanceOf(insurance.address)).to.be.equal(ETH.mul(1000));
        });
        it("Should be right insurance", async function () {
            await raw.mintTest(ETH.mul(1000));
            await raw.approve(insurance.address, ETH.mul(1000));
            tx = await insurance.stakeRaw(2628000, ETH.mul(1000));
            receipt = await tx.wait();

            insId = receipt.logs[2].topics[2];

            expect(await insurance.availableCompensation(insId)).to.be.equal(
                ETH.mul(2628000).mul(1000).div(63070000)
            );
        });
        it("Should unstake after lock time", async function () {
            await raw.mintTest(ETH.mul(1000));
            await raw.approve(insurance.address, ETH.mul(1000));
            tx = await insurance.stakeRaw(2628000, ETH.mul(1000));
            receipt = await tx.wait();

            insId = receipt.logs[2].topics[2];

            await expect(insurance.unstakeRaw(insId)).to.be.reverted;

            await ethers.provider.send("evm_increaseTime", [63070000 + 1]);
            await ethers.provider.send("evm_mine");

            await insurance.unstakeRaw(insId);
            expect(await raw.balanceOf(deployer.address)).to.be.equal(ETH.mul(1000));
        });
        it("Should delete and add correctly", async function () {
            await raw.mintTest(ETH.mul(1000));
            await raw.approve(insurance.address, ETH.mul(1000));

            await insurance.stakeRaw(2628000, ETH.mul(100)); // A
            await insurance.stakeRaw(2628000, ETH.mul(100)); // B
            await insurance.stakeRaw(2628000, ETH.mul(100)); // C
            insIdA = await insurance.userInsurances(deployer.address, 0);
            insIdB = await insurance.userInsurances(deployer.address, 1);
            insIdC = await insurance.userInsurances(deployer.address, 2);
            // correct total
            expect(await insurance.totalInsurances(deployer.address)).to.be.equal(3);
            // correct ind
            expect((await insurance.insurances(insIdB))[5]).to.be.equal(1);
            // change time
            await ethers.provider.send("evm_increaseTime", [63070000 + 1]);
            await ethers.provider.send("evm_mine");

            // unstake
            await insurance.unstakeRaw(insIdB);
            expect((await insurance.insurances(insIdA))[5]).to.be.equal(0);
            expect((await insurance.insurances(insIdB))[5]).to.be.equal(0); // deleted
            expect((await insurance.insurances(insIdC))[5]).to.be.equal(1);
            expect(await insurance.totalInsurances(deployer.address)).to.be.equal(2);
            expect(await insurance.userInsurances(deployer.address, 0)).to.be.equal(insIdA);
            expect(await insurance.userInsurances(deployer.address, 1)).to.be.equal(insIdC);

            // unstake
            await insurance.unstakeRaw(insIdA);
            expect((await insurance.insurances(insIdA))[5]).to.be.equal(0); // deleted
            expect((await insurance.insurances(insIdB))[5]).to.be.equal(0); // deleted
            expect((await insurance.insurances(insIdC))[5]).to.be.equal(0);
            expect(await insurance.totalInsurances(deployer.address)).to.be.equal(1);
            expect(await insurance.userInsurances(deployer.address, 0)).to.be.equal(insIdC);

            // unstake
            await insurance.unstakeRaw(insIdC);
            expect((await insurance.insurances(insIdA))[5]).to.be.equal(0); // deleted
            expect((await insurance.insurances(insIdB))[5]).to.be.equal(0); // deleted
            expect((await insurance.insurances(insIdC))[5]).to.be.equal(0); // deleted
            expect(await insurance.totalInsurances(deployer.address)).to.be.equal(0);
            await expect(insurance.userInsurances(deployer.address, 0)).to.be.reverted;
        });
    });
});
