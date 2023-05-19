# RunTheWeb

> Web Runners for arbitrary task execution

## Media

To know more about the project, please check

-   Watch 5 minutes video [CLICK](...)
-   Check slides [CLICK](https://docs.google.com/presentation/d/1xSQYlth2mh3vHULziAYh4BwOC0XxrypZkPIgLuj3ld8/edit?usp=sharing)
-   Try the app [CLICK](...)

## About the project

RunTheWeb is a new concept and protocol that offers delivery services for DAOs and individuals. It was started from scratch during the Chainlink 2023 hackathon.

Anyone can become a Web Runner to run delivery missions, and earn money. This makes Web Running the first massively web3 job. And unlike play-2-earn projects, it provides real value.

Web Runners hold a Soulbound Token called a Runner Soul which tracks their reputation. This reputation is very valuable and useful when executing missions. Your reputation goes up when you successfully complete missions, and goes down if you misbehave.

When Web Runners join missions, they are randomly assigned Courier or Arbiter roles. Couriers execute missions, and Arbiters judge them. Randomness, enabled by Chainlink VRF, provides safety to the protocol by removing any possibility of conspiracy.

## Our vision

Web3 is the sovereignty of cyberspace. It is the next step of the Internet. And its rules move further away from real life. One person can have multiple identities, many people can act as a single identity, and identities don’t even need to be human. Digital tools continue to improve, and anonymity starts being considered the new normal. You can be anyone, but what makes me trust you is your reputation.

Today most web3 projects that try to monetize reputation, aim at popular and rich people. That’s because those people already have a lot of reputation that they are afraid to lose.

But we think that everyone deserves to own reputation. We made a project that aims at everyone, independent of fame and wealth.

When creating RunTheWeb’s aesthetic style, we took inspiration from the video game “Death Stranding”. In it, porters make deliveries in a post-apocalyptic, divided world. Today, web3 is also a divided world, both physically (different blockchains) and mentally (atomic communities). We aim to fix that.

## Contracts overview

-   `MissionFactory` ─ contract which creates a `Mission`

-   `Mission` ─ contract which contains logic of entire mission life process (pending, initializing, execution, voting, ending). For each mission new contract should be created.

-   `RunnerSoul` ─ to become a Runner, you have to mint "Runner Soul" which is a soul-bound token. The contract implements simple soul-bound NFT logic.

-   `RtwToken` ─ the protocol governance token which used in runners collaterals and rewards. It is also 1:1 reputation price equivalent.

-   `RewardToken` ─ after a mission is completed, runners can mint reward nft (which is also soul-bound) to prove successful mission completion in the future.

-   `Treasury` ─ simple contract to collect protocol fees.

-   `PixelWar` ─ pixelwar game which is not a part of the protocol, but just a good example of using our reputation oracle outside.
