// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";

// Target contract
import { Proxy } from "src/universal/Proxy.sol";
import { Points } from "src/points/Points.sol";
import { SystemConfig } from "src/points/SystemConfig.sol";

contract PointsTest is Test {
    Proxy public proxy;
    Points public points;
    SystemConfig public systemConfig;
    address public owner = address(0x123);
    address public operator = address(0x456);

    function setUp() public {
        proxy = new Proxy({ _admin: owner });
        systemConfig = new SystemConfig();
        points = new Points();

        vm.prank(owner);
        proxy.upgradeTo(address(points));
        points = Points(address(proxy));
        points.initialize(owner, operator, address(systemConfig));
    }

    function testVersion() public view {
        assertEq(points.VERSION(), "v0.0.1");
    }

    function testInitialize() public view {
        assertEq(points.owner(), owner);
        assertEq(points.operator(), operator);
        assertEq(points.systemConfig(), address(systemConfig));
    }

    /// @dev Test case for Points: set operator
    function testSetOperator() public {
        address testOperator = address(0x789);
        vm.prank(owner);
        points.setOperator(testOperator);
        assertEq(points.operator(), testOperator);
        vm.prank(owner);
        points.setOperator(operator);
        assertEq(points.operator(), operator);
    }

    /// @dev Test case for Points: add quest
    function testAddQuest() public {
        Points.Quest memory quest =
            Points.Quest({ id: 1, name: "Quest 1", startTime: block.timestamp, endTime: block.timestamp + 1 days });

        vm.prank(operator);
        points.registerQuest(quest.id, quest.name, quest.startTime, quest.endTime);

        Points.Quest memory storedQuest = points.getQuest(1);
        assertEq(storedQuest.id, quest.id);
        assertEq(storedQuest.name, quest.name);
        assertEq(storedQuest.startTime, quest.startTime);
        assertEq(storedQuest.endTime, quest.endTime);
    }

    /// @dev Test case for Points: only operator can add quest
    function testOnlyOperatorAddQuest() public {
        Points.Quest memory quest =
            Points.Quest({ id: 1, name: "Quest 1", startTime: block.timestamp, endTime: block.timestamp + 1 days });

        vm.prank(address(0x789));
        vm.expectRevert("Points: caller is not the operator");
        points.registerQuest(quest.id, quest.name, quest.startTime, quest.endTime);
    }

    /// @dev Test case for Points: quest has been registered
    function testAddQuestReverted() public {
        Points.Quest memory quest =
            Points.Quest({ id: 1, name: "Quest 1", startTime: block.timestamp, endTime: block.timestamp + 1 days });

        vm.prank(operator);
        points.registerQuest(quest.id, quest.name, quest.startTime, quest.endTime);

        vm.prank(operator);
        vm.expectRevert("Points: quest already registered");
        points.registerQuest(quest.id, quest.name, quest.startTime, quest.endTime);
    }

    /// @dev Test case for Points: add user
    function testAddUser() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));

        vm.prank(operator);
        points.registerUser(user);

        assertEq(points.registeredUsers(user), true);
    }

    /// @dev Test case for Points: only operator can add user
    function testOnlyOperatorAddUser() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));

        vm.prank(address(0x789));
        vm.expectRevert("Points: caller is not the operator");
        points.registerUser(user);
    }

    /// @dev Test case for Points: user has been registered
    function testAddUserReverted() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));

        vm.prank(operator);
        points.registerUser(user);

        vm.prank(operator);
        vm.expectRevert("Points: user already registered");
        points.registerUser(user);
    }

    /// @dev Test case for Points: submit quest
    function testSubmitQuest() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));
        Points.Quest memory quest =
            Points.Quest({ id: 1, name: "Quest 1", startTime: block.timestamp, endTime: block.timestamp + 1 days });

        vm.prank(operator);
        points.registerQuest(quest.id, quest.name, quest.startTime, quest.endTime);

        vm.prank(operator);
        points.registerUser(user);

        vm.prank(operator);
        points.submitQuest(user, quest.id);

        Points.Submission memory submission = points.getSubmission(user, quest.id);
        assertEq(submission.questId, quest.id);
        assertEq(submission.user, user);
        assertEq(submission.timestamp, block.timestamp);
        assertEq(submission.points, 0);
    }

    /// @dev Test case for Points: only operator can submit quest
    function testOnlyOperatorSubmitQuest() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));
        Points.Quest memory quest =
            Points.Quest({ id: 1, name: "Quest 1", startTime: block.timestamp, endTime: block.timestamp + 1 days });

        vm.prank(operator);
        points.registerQuest(quest.id, quest.name, quest.startTime, quest.endTime);

        vm.prank(operator);
        points.registerUser(user);

        vm.prank(address(0x789));
        vm.expectRevert("Points: caller is not the operator");
        points.submitQuest(user, quest.id);
    }

    /// @dev Test case for Points: quest has been submitted
    function testSubmitQuestReverted() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));
        Points.Quest memory quest =
            Points.Quest({ id: 1, name: "Quest 1", startTime: block.timestamp, endTime: block.timestamp + 1 days });

        vm.prank(operator);
        points.registerQuest(quest.id, quest.name, quest.startTime, quest.endTime);

        vm.prank(operator);
        points.registerUser(user);

        vm.prank(operator);
        points.submitQuest(user, quest.id);

        vm.prank(operator);
        vm.expectRevert("Points: quest already submitted");
        points.submitQuest(user, quest.id);
    }

    /// @dev Test case for Points: quest not started
    function testSubmitQuestOutOfTimestamp() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));
        Points.Quest memory quest = Points.Quest({
            id: 1,
            name: "Quest 1",
            startTime: block.timestamp + 1 days,
            endTime: block.timestamp + 2 days
        });

        vm.prank(operator);
        points.registerQuest(quest.id, quest.name, quest.startTime, quest.endTime);

        vm.prank(operator);
        points.registerUser(user);

        vm.prank(operator);
        vm.expectRevert("Points: quest not started");
        points.submitQuest(user, quest.id);

        vm.warp(block.timestamp + 3 days);
        vm.prank(operator);
        vm.expectRevert("Points: quest ended");
        points.submitQuest(user, quest.id);
    }

    /// @dev Test case for Points: add points
    function testAddPoints() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));
        Points.Quest memory quest =
            Points.Quest({ id: 1, name: "Quest 1", startTime: block.timestamp, endTime: block.timestamp + 1 days });

        vm.prank(operator);
        points.registerQuest(quest.id, quest.name, quest.startTime, quest.endTime);

        vm.prank(operator);
        points.registerUser(user);

        vm.prank(operator);
        points.submitQuest(user, quest.id);

        vm.prank(operator);
        points.addPoints(user, quest.id, 100);

        Points.Submission memory submission = points.getSubmission(user, quest.id);
        assertEq(submission.points, 100);
    }

    /// @dev Test case for Points: only operator can add points
    function testOnlyOperatorAddPoints() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));
        Points.Quest memory quest =
            Points.Quest({ id: 1, name: "Quest 1", startTime: block.timestamp, endTime: block.timestamp + 1 days });

        vm.prank(operator);
        points.registerQuest(quest.id, quest.name, quest.startTime, quest.endTime);

        vm.prank(operator);
        points.registerUser(user);

        vm.prank(operator);
        points.submitQuest(user, quest.id);

        vm.prank(address(0x789));
        vm.expectRevert("Points: caller is not the operator");
        points.addPoints(user, quest.id, 100);
    }

    /// @dev Test case for Points: quest not submitted
    function testAddPointsReverted() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));
        Points.Quest memory quest =
            Points.Quest({ id: 1, name: "Quest 1", startTime: block.timestamp, endTime: block.timestamp + 1 days });

        vm.prank(operator);
        points.registerQuest(quest.id, quest.name, quest.startTime, quest.endTime);

        vm.prank(operator);
        points.registerUser(user);

        vm.prank(operator);
        vm.expectRevert("Points: quest not submitted");
        points.addPoints(user, quest.id, 100);
    }

    /// @dev Test case for Points: user not registered
    function testAddPointsRevertedUserNotRegistered() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));
        Points.Quest memory quest =
            Points.Quest({ id: 1, name: "Quest 1", startTime: block.timestamp, endTime: block.timestamp + 1 days });

        vm.prank(operator);
        points.registerQuest(quest.id, quest.name, quest.startTime, quest.endTime);

        vm.prank(operator);
        vm.expectRevert("Points: user not registered");
        points.addPoints(user, quest.id, 100);
    }
}
