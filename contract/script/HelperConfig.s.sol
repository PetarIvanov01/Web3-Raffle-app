// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console, console2} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    /* VRF Mock constants */
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE = 1e9;
    /* LINK/ETH price */
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;

    address public FOUNDRY_DEFAULT_SENDER =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig_InvalidChainId();

    struct NetworkConfig {
        uint256 minUsersToStart;
        uint256 subscriptionId;
        bytes32 gasLane;
        uint256 interval;
        uint256 entranceFee;
        uint32 callbackGasLimit;
        address vrfCoordinatorV2;
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function setConfig(
        uint256 chainId,
        NetworkConfig memory networkConfig
    ) public {
        networkConfigs[chainId] = networkConfig;
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinatorV2 != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig_InvalidChainId();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                minUsersToStart: 3,
                entranceFee: 0.01 ether, // 1e16
                interval: 30, //seconds
                vrfCoordinatorV2: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                callbackGasLimit: 500000,
                subscriptionId: 87471519237615015178332551730664687679378159971537164020190526063443369702486,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                account: 0xC6790119AcfbEbbb29754f4f03071C28274870E8
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinatorV2 != address(0)) {
            return localNetworkConfig;
        }
        console2.log(unicode"⚠️ You have deployed a mock conract!");
        console2.log("Make sure this was intentional");

        vm.startBroadcast(FOUNDRY_DEFAULT_SENDER);
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE,
            MOCK_WEI_PER_UNIT_LINK
        );
        LinkToken linkToken = new LinkToken();
        uint256 subscriptionId = vrfCoordinatorMock.createSubscription();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            minUsersToStart: 2,
            subscriptionId: subscriptionId,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            interval: 30, //seconds
            entranceFee: 0.01 ether, // 1e16
            callbackGasLimit: 500000,
            vrfCoordinatorV2: address(vrfCoordinatorMock),
            link: address(linkToken),
            account: FOUNDRY_DEFAULT_SENDER
        });
        vm.deal(localNetworkConfig.account, 100 ether);
        return localNetworkConfig;
    }
}
