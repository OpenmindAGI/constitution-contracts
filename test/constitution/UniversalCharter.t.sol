// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";

// Target contract
import { Proxy } from "src/universal/Proxy.sol";
import { UniversalCharter } from "src/constitution/UniversalCharter.sol";
import { SystemConfig } from "src/constitution/SystemConfig.sol";

contract UniversalCharterTest is Test {
    Proxy public universalCharterProxy;
    UniversalCharter public universalCharter;

    Proxy public systemConfigProxy;
    SystemConfig public systemConfig;

    address public owner = address(0x123);

    function setUp() public {
        universalCharterProxy = new Proxy({ _admin: owner });
        universalCharter = new UniversalCharter();

        systemConfigProxy = new Proxy({ _admin: owner });
        systemConfig = new SystemConfig();

        vm.startPrank(owner);

        universalCharterProxy.upgradeTo(address(universalCharter));
        universalCharter = UniversalCharter(address(universalCharterProxy));
        universalCharter.initialize(owner, address(systemConfigProxy));

        systemConfigProxy.upgradeTo(address(systemConfig));
        systemConfig = SystemConfig(address(systemConfigProxy));
        systemConfig.initialize(owner);

        vm.stopPrank();
    }

    /// @dev Test that the version is set correctly.
    function testVersion() public view {
        assertEq(universalCharter.VERSION(), "v0.0.1");
    }

    /// @dev Test that the owner is set correctly.
    function testInitialize() public view {
        assertEq(universalCharter.owner(), owner);
        assertEq(address(universalCharter.systemConfig()), address(systemConfig));
    }

    /// @dev Test rule set can be added and retrieved.
    function testUpdateRuleSet() public {
        vm.startPrank(owner);

        uint256 ruleSetId = 1;
        bytes memory rule = abi.encodePacked("rule");
        bytes memory rule2 = abi.encodePacked("rule2");
        bytes[] memory ruleSet = new bytes[](2);
        ruleSet[0] = rule;
        ruleSet[1] = rule2;

        universalCharter.updateRuleSet(ruleSet);

        assertEq(universalCharter.getLatestRuleSetVersion(), 1);

        bytes[] memory readRuleSet = universalCharter.getRuleSet(ruleSetId);
        assertEq(readRuleSet.length, 2);
        assertEq(readRuleSet[0], ruleSet[0]);
        assertEq(readRuleSet[1], ruleSet[1]);

        bytes32 ruleSetHash = keccak256(abi.encode(ruleSet));
        assertEq(universalCharter.getRuleSetVersion(ruleSetHash), ruleSetId);

        vm.expectRevert("Rule set already registered");
        universalCharter.updateRuleSet(ruleSet);

        bytes memory rule3 = abi.encodePacked("rule3");
        ruleSet[1] = rule3;
        universalCharter.updateRuleSet(ruleSet);
        assertEq(universalCharter.getLatestRuleSetVersion(), 2);

        vm.stopPrank();
    }

    /// @dev Test that only the owner can update the rule set.
    function testUpdateRuleSetOnlyOwner() public {
        bytes memory rule = abi.encodePacked("rule");
        bytes[] memory ruleSet = new bytes[](1);
        ruleSet[0] = rule;

        vm.prank(address(0x456));
        vm.expectRevert("Ownable: caller is not the owner");
        universalCharter.updateRuleSet(ruleSet);
    }

    /// @dev Test that the rule set cannot be updated to an empty rule set.
    function testUpdateRuleSetEmptyReverted() public {
        bytes[] memory ruleSet = new bytes[](0);

        vm.expectRevert("Cannot update to an empty rule set");
        vm.prank(owner);
        universalCharter.updateRuleSet(ruleSet);
    }

    /// @dev Test that the system can be paused.
    function testPause() public {
        vm.startPrank(owner);
        systemConfig.pause();
        assertTrue(universalCharter.paused());

        vm.expectRevert();
        bytes memory rule = abi.encodePacked("rule");
        bytes[] memory ruleSet = new bytes[](1);
        ruleSet[0] = rule;
        universalCharter.updateRuleSet(ruleSet);

        vm.stopPrank();
    }
}
