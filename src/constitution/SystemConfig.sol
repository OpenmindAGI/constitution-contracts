// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// @title SystemConfig
/// @notice The SystemConfig contract is used to manage configuration of the points system.

contract SystemConfig is OwnableUpgradeable {
    /// @notice Version identifier for the current implementation of the contract.
    string public constant VERSION = "v0.0.1";

    /// @notice Whether the system is paused.
    bytes32 public constant PAUSED_SLOT = keccak256("SystemConfig.Paused");

    /// @notice Constucts the SystemConfig contract.
    constructor() {
        initialize({ _owner: address(0xdEaD) });
    }

    /// @notice Initializes the SystemConfig contract.
    function initialize(address _owner) public initializer {
        __Ownable_init();
        transferOwnership(_owner);
    }

    /// @notice Pauses the system.
    function pause() public onlyOwner {
        _setPaused(true);
    }

    /// @notice Unpauses the system.
    function unpause() public onlyOwner {
        _setPaused(false);
    }

    /// @notice Returns whether the system is paused.
    function paused() public view returns (bool) {
        return _getPaused();
    }

    /// @notice Sets whether the system is paused.
    /// @param _paused Whether the system is paused.
    function _setPaused(bool _paused) internal {
        _setBool(PAUSED_SLOT, _paused);
    }

    /// @notice Returns whether the system is paused.
    function _getPaused() internal view returns (bool) {
        return _getBool(PAUSED_SLOT);
    }

    /// @notice Returns a boolean value from storage.
    /// @param slot The storage slot to get.
    function _getBool(bytes32 slot) internal view returns (bool value) {
        assembly {
            value := sload(slot)
        }
    }

    /// @notice Sets a boolean value in storage.
    /// @param slot The storage slot to set.
    /// @param value The value to set.
    function _setBool(bytes32 slot, bool value) internal {
        assembly {
            sstore(slot, value)
        }
    }
}
