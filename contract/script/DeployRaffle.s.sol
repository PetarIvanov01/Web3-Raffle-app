// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Raffle} from "src/Raffle.sol";
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        AddConsumer addConsumer = new AddConsumer();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            // createa subscription
            CreateSubscription create = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinatorV2) = create
                .createSubscription(config.vrfCoordinatorV2, config.account);
            // Fund with link
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinatorV2,
                config.subscriptionId,
                config.link,
                config.account
            );

            helperConfig.setConfig(block.chainid, config);
        }

        vm.startBroadcast(config.account);
        Raffle raffleContract = new Raffle(
            config.subscriptionId,
            config.gasLane,
            config.interval,
            config.entranceFee,
            config.callbackGasLimit,
            config.vrfCoordinatorV2
        );

        vm.stopBroadcast();

        addConsumer.addConsumer(
            address(raffleContract),
            config.vrfCoordinatorV2,
            config.subscriptionId,
            config.account
        );

        return (raffleContract, helperConfig);
    }
}
