// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {console} from "forge-std/console.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @author  Sample Raffle contract
 * @title   Petar Ivanov
 * @dev     Implements Chailink VRFv2.5
 * @notice  This contract is for creating a sample raffle
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__NotEnoughEthToBuyATicket();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 length,
        uint256 state
    );
    error Raffle__FailedWithdraw();
    error Raffle__LotteryNotOpen();
    /* Type Declarations */

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    /* State variables */
    // Chainlink VRF Variables
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;

    uint256 private immutable i_min_users_to_start;
    uint256 private immutable i_entranceFee;
    // @dev Duration of the lottery in seconds
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    address payable[] private s_listOfEnteredPlayers;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 minUsersToStart,
        uint256 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) {
        i_min_users_to_start = minUsersToStart;
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(i_entranceFee >= msg.value, "Not enough ETH to buy a ticket!");
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__LotteryNotOpen();
        }
        if (i_entranceFee > msg.value) {
            revert Raffle__NotEnoughEthToBuyATicket();
        }
        s_listOfEnteredPlayers.push(payable(msg.sender));
        // Users should be able to buy a ticket and participate in th raffle
        // Users should pay some Raffle entrence fee to get added to the pool
        emit RaffleEntered(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >=
            i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_listOfEnteredPlayers.length >= i_min_users_to_start;

        if (timeHasPassed && isOpen && hasBalance && hasPlayers) {
            upkeepNeeded = true;
        }
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        // Picking a winner
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_listOfEnteredPlayers.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata randomWords
    ) internal override {
        /* Checks (Validations) */
        uint256 indexOfWinner = randomWords[0] % s_listOfEnteredPlayers.length;
        address payable recentWinner = s_listOfEnteredPlayers[indexOfWinner];

        /* Effects (Internal Contract State) */
        s_raffleState = RaffleState.OPEN;
        s_listOfEnteredPlayers = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        s_recentWinner = recentWinner;

        emit WinnerPicked(s_recentWinner);

        /* Interactions (External Contract Interactions) */
        (bool sent, ) = recentWinner.call{value: address(this).balance}("");
        if (!sent) {
            revert Raffle__FailedWithdraw();
        }
    }

    /** Getter Functions / Pure */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_listOfEnteredPlayers[index];
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getInterval() external view returns (uint256) {
        return i_interval;
    }

    function getNumberOfPlayers() external view returns (uint256) {
        return s_listOfEnteredPlayers.length;
    }

    function getMinimumPlayersToStart() external view returns (uint256) {
        return i_min_users_to_start;
    }
}
