// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";

// Target contract
import { Proxy } from "src/universal/Proxy.sol";
import { UniversalCharter } from "src/constitution/UniversalCharter.sol";
import { UniversalIdentity } from "src/constitution/UniversalIdentity.sol";
import { SystemConfig } from "src/constitution/SystemConfig.sol";

// interface
import { IUniversalCharter } from "src/constitution/interface/IUniversalCharter.sol";

contract UniversalIdentityTest is Test {
    Proxy public universalCharterProxy;
    UniversalCharter public universalCharter;

    Proxy public universalIdentityProxy;
    UniversalIdentity public universalIdentity;

    Proxy public systemConfigProxy;
    SystemConfig public systemConfig;

    address public owner = address(0x123);

    function setUp() public {
        universalCharterProxy = new Proxy({ _admin: owner });
        universalCharter = new UniversalCharter();

        universalIdentityProxy = new Proxy({ _admin: owner });
        universalIdentity = new UniversalIdentity();

        systemConfigProxy = new Proxy({ _admin: owner });
        systemConfig = new SystemConfig();

        vm.startPrank(owner);

        universalCharterProxy.upgradeTo(address(universalCharter));
        universalCharter = UniversalCharter(address(universalCharterProxy));
        universalCharter.initialize(owner, address(systemConfigProxy));

        systemConfigProxy.upgradeTo(address(systemConfig));
        systemConfig = SystemConfig(address(systemConfigProxy));
        systemConfig.initialize(owner);

        universalIdentityProxy.upgradeTo(address(universalIdentity));
        universalIdentity = UniversalIdentity(address(universalIdentityProxy));
        universalIdentity.initialize(owner);

        vm.stopPrank();
    }

    /// @dev Test that the version is set correctly.
    function testVersion() public view {
        assertEq(universalIdentity.VERSION(), "v0.0.1");
    }

    /// @dev Test that the owner is set correctly.
    function testInitialize() public view {
        assertEq(universalIdentity.owner(), owner);
    }

    /// @dev Test that the rule can be added.
    function testAddRule() public {
        vm.startPrank(owner);

        bytes memory rule = abi.encodePacked("rule");
        universalIdentity.addRule(rule);
        assertEq(universalIdentity.getRule(rule), true);

        vm.stopPrank();
    }

    /// @dev Test that the rule can be removed.
    function testRemoveRule() public {
        vm.startPrank(owner);

        bytes memory rule = abi.encodePacked("rule");
        universalIdentity.addRule(rule);
        assertEq(universalIdentity.getRule(rule), true);
        universalIdentity.removeRule(rule);
        assertEq(universalIdentity.getRule(rule), false);

        vm.stopPrank();
    }

    /// @dev Test that only the owner can add a rule.
    function testAddRuleOnlyOwner() public {
        bytes memory rule = abi.encodePacked("rule");
        vm.prank(address(0x456));
        vm.expectRevert("Ownable: caller is not the owner");
        universalIdentity.addRule(rule);
    }

    /// @dev Test that only the owner can remove a rule.
    function testRemoveRuleOnlyOwner() public {
        bytes memory rule = abi.encodePacked("rule");
        vm.prank(address(0x456));
        vm.expectRevert("Ownable: caller is not the owner");
        universalIdentity.removeRule(rule);
    }

    /// @dev Test that the user can be registered.
    function testRegisterUserAsHuman() public {
        bytes memory rule = abi.encodePacked("rule");
        bytes[] memory ruleSet = new bytes[](1);
        ruleSet[0] = rule;

        vm.startPrank(owner);

        universalCharter.updateRuleSet(ruleSet);
        assertEq(universalCharter.getLatestRuleSetVersion(), 1);

        universalIdentity.addRule(rule);
        assertEq(universalIdentity.getRule(rule), true);

        universalCharter.registerUser(IUniversalCharter.UserType.Human, ruleSet);
        UniversalCharter.UserInfo memory userInfo = universalCharter.getUserInfo(owner);
        assertEq(userInfo.isRegistered, true);
        assertEq(uint256(userInfo.userType), uint256(IUniversalCharter.UserType.Human));
        assertEq(userInfo.ruleSetVersion, 1);

        vm.stopPrank();
    }

    /// @dev Test that the user can be registered.
    function testRegisterUserAsRobot() public {
        bytes memory rule = abi.encodePacked("rule");
        bytes[] memory ruleSet = new bytes[](1);
        ruleSet[0] = rule;

        vm.startPrank(owner);

        universalCharter.updateRuleSet(ruleSet);
        assertEq(universalCharter.getLatestRuleSetVersion(), 1);

        universalIdentity.addRule(rule);
        assertEq(universalIdentity.getRule(rule), true);

        universalIdentity.subscribeAndRegisterToCharter(address(universalCharter), 1);
        assertEq(universalIdentity.getSubscribedCharters(address(universalCharter)), true);

        UniversalCharter.UserInfo memory userInfo = universalCharter.getUserInfo(address(universalIdentity));
        assertEq(userInfo.isRegistered, true);
        assertEq(uint256(userInfo.userType), uint256(IUniversalCharter.UserType.Robot));
        assertEq(userInfo.ruleSetVersion, 1);

        vm.stopPrank();
    }

    /// @dev Test that the user can register only once.
    function testRegisterUserOnlyOnce() public {
        testRegisterUserAsRobot();

        vm.startPrank(owner);

        bytes memory rule = abi.encodePacked("rule");
        bytes[] memory ruleSet = new bytes[](1);
        ruleSet[0] = rule;

        vm.expectRevert("Already subscribed to this charter");
        universalIdentity.subscribeAndRegisterToCharter(address(universalCharter), 1);

        vm.stopPrank();
    }

    /// @dev Test that the invalid rule is reverted.
    function testRegisterUserReverted() public {
        bytes memory rule = abi.encodePacked("rule");
        bytes[] memory ruleSet = new bytes[](1);
        ruleSet[0] = rule;

        vm.startPrank(owner);

        universalCharter.updateRuleSet(ruleSet);
        assertEq(universalCharter.getLatestRuleSetVersion(), 1);

        universalIdentity.addRule(abi.encodePacked("invalid rule"));

        vm.expectRevert(abi.encodeWithSignature("RuleNotAgreed(bytes)", rule));
        universalIdentity.subscribeAndRegisterToCharter(address(universalCharter), 1);

        vm.stopPrank();
    }

    /// @dev Test that the user can leave the system.
    function testLeaveSystem() public {
        testRegisterUserAsRobot();

        vm.startPrank(owner);

        universalIdentity.leaveCharter(address(universalCharter));
        assertEq(universalIdentity.getSubscribedCharters(address(universalCharter)), false);

        UniversalCharter.UserInfo memory userInfo = universalCharter.getUserInfo(address(universalIdentity));
        assertEq(userInfo.isRegistered, false);
        assertEq(uint256(userInfo.userType), uint256(IUniversalCharter.UserType.Human));
        assertEq(userInfo.ruleSetVersion, 0);

        vm.stopPrank();
    }

    /// @dev Test that the user can leave the system only once.
    function testLeaveSystemOnlyOnce() public {
        testLeaveSystem();

        vm.startPrank(owner);

        vm.expectRevert("Not subscribed to this charter");
        universalIdentity.leaveCharter(address(universalCharter));

        vm.stopPrank();
    }

    /// @dev Test that the robot can leave the system if the rule is removed.
    function testLeaveSystemReverted() public {
        testRegisterUserAsRobot();

        vm.startPrank(owner);

        bytes memory rule = abi.encodePacked("rule");
        universalIdentity.removeRule(rule);

        vm.expectRevert(abi.encodeWithSignature("RuleNotAgreed(bytes)", rule));
        universalIdentity.leaveCharter(address(universalCharter));

        vm.stopPrank();
    }
}
