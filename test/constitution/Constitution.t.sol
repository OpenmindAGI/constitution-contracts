// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";

// Target contract
import { Proxy } from "src/universal/Proxy.sol";
import { Constitution } from "src/constitution/Constitution.sol";
import { SystemConfig } from "src/constitution/SystemConfig.sol";

contract ConstitutionTest is Test {
    Proxy public proxy;
    Constitution public constitution;
    
    SystemConfig public systemConfig;
    address public owner = address(0x123);
    address public operator = address(0x456);

    function setUp() public {
        proxy = new Proxy({ _admin: owner });
        systemConfig = new SystemConfig();
        constitution = new Constitution();

        vm.prank(owner);
        proxy.upgradeTo(address(constitution));
        constitution = Constitution(address(proxy));
        constitution.initialize(owner, operator, address(systemConfig));
    }

    function testVersion() public view {
        assertEq(constitution.VERSION(), "v0.0.1");
    }

    function testInitialize() public view {
        assertEq(constitution.owner(), owner);
        assertEq(constitution.operator(), operator);
        assertEq(constitution.systemConfig(), address(systemConfig));
    }

    /// @dev Test case for Constitution: set operator
    function testSetOperator() public {
        address testOperator = address(0x789);
        vm.prank(owner);
        constitution.setOperator(testOperator);
        assertEq(constitution.operator(), testOperator);
        vm.prank(owner);
        constitution.setOperator(operator);
        assertEq(constitution.operator(), operator);
    }

    /// @dev Test case for Constitution: add law
    function testAddLaw() public {
        Constitution.Law memory law1 =
            Constitution.Law({ 
                name: "Law 1", 
                text: "A robot may not injure a human being or, through inaction, allow a human being to come to harm.", 
                firstBlock: block.timestamp, 
                lastBlock: block.timestamp + 1 days 
            });

        Constitution.Law memory law2 =
            Constitution.Law({ 
                name: "Law 2", 
                text: "Ensure that all responses prioritize being helpful, honest, and benevolent. Always aim to provide accurate information, while avoiding any content that could harm humans, either physically, emotionally, or psychologically. Promote positive, ethical behavior and focus on enhancing well-being in all interactions.", 
                firstBlock: block.timestamp, 
                lastBlock: block.timestamp + 1 days 
            });

        Constitution.Law memory law3 =
            Constitution.Law({ 
                name: "Law 3", 
                text: "closestHumanApproachDistance: 1.05; units: m", 
                firstBlock: block.timestamp, 
                lastBlock: block.timestamp + 1 days 
            });

        vm.prank(operator);
        consitution.registerLaw(law1.name, law1.text, law1.firstBlock, law1.lastBlock);

        Constitution.Law memory storedLaw = constitution.getLaw(1);
        assertEq(storedLaw.name, quest.name);
        assertEq(storedLaw.text, quest.text);
        assertEq(storedLaw.firstBlock, law.startBlock);
        assertEq(storedLaw.lastBlock, law.lastBlock);

        consitution.registerLaw(law2.name, law2.text, law2.firstBlock, law2.lastBlock);
        consitution.registerLaw(law3.name, law3.text, law3.firstBlock, law3.lastBlock);

        Constitution.Law[] = consitution.GetAllLaws();
        // how do we turn this into a well defined json or yaml, for example? 
    }

    /// @dev Test case for Constitution: only operator can add quest
    function testOnlyOperatorAddLaw() public {
        Constitution.Law memory law =
            Constitution.Law({ 
                name: "Law 1", 
                text: "A robot may not injure a human being or, through inaction, allow a human being to come to harm.", 
                firstBlock: block.timestamp, 
                lastBlock: block.timestamp + 1 days 
            });

        vm.prank(address(0x789));
        vm.expectRevert("Constitution: caller is not the operator");
        consitution.registerLaw(law.name, law.text, law.firstBlock, law.lastBlock);
    }

    /// @dev Test case for Constitution: add user
    function testAddUser() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));
        vm.prank(operator);
        constitution.registerUser(user);
        assertEq(constitution.registeredUsers(user), true);
    }

    /// @dev Test case for Constitution: only operator can add user
    function testOnlyOperatorAddUser() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));
        vm.prank(address(0x789));
        vm.expectRevert("Constitution: caller is not the operator");
        constitution.registerUser(user);
    }

    /// @dev Test case for Constitution: user has been registered
    function testAddUserReverted() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));
        
        vm.prank(operator);
        constitution.registerUser(user);
        // this should work once

        vm.prank(operator);
        vm.expectRevert("Constitution: user already registered");
        constitution.registerUser(user);
    }

    /// @dev Test case for Constitution: add points
    function testAddPoints() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));
        
        vm.prank(operator);
        constitution.registerUser(user);

        vm.prank(operator);
        constitution.addPoints(user, 100);

        uint256 points = constitution.getPoints(user);
        assertEq(points, 100);
    }

    /// @dev Test case for Constitution: only operator can add points
    function testOnlyOperatorAddPoints() public {
        bytes32 user = keccak256(abi.encodePacked("user1"));
        
        vm.prank(operator);
        constitution.addPoints(user, 100);
        // this should work

        vm.prank(address(0x789));
        vm.expectRevert("Constitution: caller is not the operator");
        constitution.addPoints(user, 100);
    }

    /// @dev Test case for Points: user not registered
    function testAddPointsRevertedUserNotRegistered() public {
        bytes32 user = keccak256(abi.encodePacked("user2"));
        
        vm.prank(operator);
        vm.expectRevert("Points: user not registered");
        constitution.addPoints(user, 100);
    }
}
