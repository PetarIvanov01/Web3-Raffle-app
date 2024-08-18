// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../../test/mocks/LinkToken.sol";
import {CodeConstants} from "../../script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";

contract RaffleTest is Test, CodeConstants {
    event RaffleEntered(address indexed player);

    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 minUsersToStart;
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinatorV2;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;
    LinkToken link;

    address public PLAYER = makeAddr("player");
    address public PLAYER2 = makeAddr("player2");

    uint256 public constant ENTRANCE = 1 ether;
    uint256 public constant START_BALANCE = 10 ether;
    uint256 public constant LINK_BALANCE = 100 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        vm.deal(PLAYER, START_BALANCE);
        vm.deal(PLAYER2, START_BALANCE);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        minUsersToStart = config.minUsersToStart;
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinatorV2 = config.vrfCoordinatorV2;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;
        link = LinkToken(config.link);

        vm.startPrank(msg.sender);
        if (block.chainid == LOCAL_CHAIN_ID) {
            link.mint(msg.sender, LINK_BALANCE);
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2).fundSubscription(
                subscriptionId,
                LINK_BALANCE
            );
        }
        link.approve(vrfCoordinatorV2, LINK_BALANCE);
        vm.stopPrank();
    }

    /*/////////////////////////////////////////////////////
                        ENTER Raffle
    /////////////////////////////////////////////////////*/

    function testRaffleInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testMinimumUsersToStart() public view {
        assert(raffle.getMinimumPlayersToStart() == minUsersToStart);
    }

    function testRaffleEntranceRevertNoEnoughEth() public payable {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthToBuyATicket.selector);
        raffle.enterRaffle();
    }

    function testRafflePlayerEnterRaffleIsInList() public raffleEntered {
        uint256 expectedBalance = START_BALANCE - ENTRANCE;

        vm.assertEq(address(PLAYER).balance, expectedBalance);
        vm.assertEq(address(PLAYER2).balance, expectedBalance);

        vm.assertEq(address(raffle).balance, ENTRANCE * 2);

        vm.assertEq(raffle.getPlayer(0), address(PLAYER));
    }

    function testEnteringRaffleEmitsEvent() public {
        uint256 entrance = 1 ether;
        vm.prank(PLAYER);

        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);

        raffle.enterRaffle{value: entrance}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating()
        public
        raffleEntered
    {
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__LotteryNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE}();
    }

    /*//////////////////////////////////////////////////////////////
                              CHECKUPKEEP
    //////////////////////////////////////////////////////////////*/

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE}();

        vm.prank(PLAYER2);
        raffle.enterRaffle{value: ENTRANCE}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(raffleState == Raffle.RaffleState.CALCULATING);
        assert(upkeepNeeded == false);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE}();

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(upkeepNeeded == false);
    }

    function testCheckUpkeepReturnsTrueWhenParametersGood() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE}();

        vm.prank(PLAYER2);
        raffle.enterRaffle{value: ENTRANCE}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assert(raffleState == Raffle.RaffleState.OPEN);
        assert(upkeepNeeded == true);
    }

    /*//////////////////////////////////////////////////////////////
                             PERFORMUPKEEP
    //////////////////////////////////////////////////////////////*/

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue()
        public
        raffleEntered
    {
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                rState
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEntered
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1); // 0 = open, 1 = calculating
    }

    /*//////////////////////////////////////////////////////////////
                           FULFILLRANDOMWORDS
    //////////////////////////////////////////////////////////////*/

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ENTRANCE}();

        vm.prank(PLAYER2);
        raffle.enterRaffle{value: ENTRANCE}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 requestId
    ) public skipFork raffleEntered {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2).fulfillRandomWords(
            requestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        skipFork
        raffleEntered
    {
        //Arange
        uint256 additionalEntrants = 3; // 5 total
        uint256 index = minUsersToStart;
        address expectedWinner = address(PLAYER2);

        for (uint256 i = index; i < index + additionalEntrants; i++) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: ENTRANCE}();
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;
        uint256 totalPlayers = raffle.getNumberOfPlayers();
        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2_5Mock(vrfCoordinatorV2).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        //Assert
        address recentWinner = raffle.getRecentWinner();

        Raffle.RaffleState rState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;

        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = ENTRANCE * (additionalEntrants + minUsersToStart);

        assert(totalPlayers == additionalEntrants + minUsersToStart);
        assert(recentWinner == expectedWinner);
        assert(uint256(rState) == 0);
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
