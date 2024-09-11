// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Testing utilities
import "forge-std/Test.sol";

// Target contract
import { Proxy } from "src/universal/Proxy.sol";
import { SystemConfig } from "src/points/SystemConfig.sol";

contract SystemConfigTest is Test {
    SystemConfig public systemConfig;
    Proxy public proxy;

    address public owner = address(0x123);
    address public addr1 = address(0x456);

    function setUp() public {
        proxy = new Proxy({ _admin: owner });
        systemConfig = new SystemConfig();

        vm.prank(owner);
        proxy.upgradeTo(address(systemConfig));
        systemConfig = SystemConfig(address(proxy));
        systemConfig.initialize(owner);
    }

    /// @dev Test that the version is set correctly.
    function testVersion() public view {
        assertEq(systemConfig.VERSION(), "v0.0.1");
    }

    /// @dev Test that the owner is set correctly.
    function testOwner() public view {
        assertEq(systemConfig.owner(), owner);
    }

    /// @dev Test that the system can be paused.
    function testPause() public {
        vm.prank(owner);
        systemConfig.pause();
        assertTrue(systemConfig.paused());
    }

    /// @dev Test that the system can be unpaused.
    function testUnpause() public {
        vm.prank(owner);
        systemConfig.pause();
        vm.prank(owner);
        systemConfig.unpause();
        assertFalse(systemConfig.paused());
    }

    /// @dev Test that only the owner can pause the system.
    function testOnlyOwnerCanPause() public {
        vm.prank(addr1);
        vm.expectRevert("Ownable: caller is not the owner");
        systemConfig.pause();
    }

    /// @dev Test that only the owner can unpause the system.
    function testOnlyOwnerCanUnpause() public {
        vm.prank(owner);
        systemConfig.pause();
        vm.prank(addr1);
        vm.expectRevert("Ownable: caller is not the owner");
        systemConfig.unpause();
    }
}
