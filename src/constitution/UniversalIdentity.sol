// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Interfaces
import { IUniversalIdentity } from "./interface/IUniversalIdentity.sol";

/// @title UniversalIdentity
/// @notice The UniversalIdentity contract is used to manage the identity of robots.

contract UniversalIdentity is IUniversalIdentity, OwnableUpgradeable {

    /// @notice Version identifier for the current implementation of the contract.
    string public constant VERSION = "v0.0.1";

    /// @notice Mapping to store rules that the robot has agreed to follow
    mapping(bytes => bool) private robotRules;

    /// @notice Mapping to store the off-chain compliance status for each rule
    mapping(bytes => bool) private complianceStatus;

    /// @notice Custom errors to save gas on reverts
    error RuleNotAgreed(bytes rule);
    error RuleNotCompliant(bytes rule);
    error RuleAlreadyAdded(bytes rule);

    /// @dev Event to emit when compliance is checked
    /// @param updater The address of the trusted compliance updater
    /// @param rule The rule that was checked
    event ComplianceChecked(address indexed updater, bytes rule);

    /// @notice Modifier to check if a rule exists
    modifier ruleExists(bytes memory rule) {
        require(robotRules[rule], "Rule does not exist");
        _;
    }

    /// @notice Constructor to set the trusted compliance updater
    constructor() {
        initialize({ _owner: address(0xdEaD) });
    }

    /// @dev Initializer function
    function initialize(address _owner) public initializer {
        __Ownable_init();
        transferOwnership(_owner);
    }

    /// @notice Adds a rule to the robot's identity
    /// @param rule The dynamic byte array representing the rule that the robot agrees to follow.
    function addRule(bytes memory rule) external override onlyOwner {
        if (robotRules[rule]) {
            revert RuleAlreadyAdded(rule);
        }

        // Add rule to the mapping
        robotRules[rule] = true;

        emit RuleAdded(rule);
    }

    /// @notice Removes a rule from the robot's identity
    /// @param rule The dynamic byte array representing the rule that the robot no longer agrees to follow.
    function removeRule(bytes memory rule) external override onlyOwner ruleExists(rule) {
        robotRules[rule] = false;
        complianceStatus[rule] = false;

        emit RuleRemoved(rule);
    }

    /// @notice Updates compliance status for a rule (called by the owner)
    /// @param rule The dynamic byte array representing the rule
    /// @param status The compliance status (true if compliant, false if not)
    function updateCompliance(bytes memory rule, bool status) external onlyOwner ruleExists(rule) {
        complianceStatus[rule] = status;

        emit ComplianceChecked(msg.sender, rule);  // ComplianceChecked event needs to be declared
    }

    /// @notice Checks if the robot has agreed to follow a specific rule and if it is compliant
    /// @param rule The rule to check.
    /// @return bool Returns true if the robot has agreed to the rule and is compliant
    function checkCompliance(bytes memory rule) external view override returns (bool) {
        if (!robotRules[rule]) {
            revert RuleNotAgreed(rule);
        }

        if (!complianceStatus[rule]) {
            revert RuleNotCompliant(rule);
        }

        return true;
    }

    /// @notice Gets the compliance status of a rule
    /// @param rule The rule to check.
    function getRule(bytes memory rule) external view returns (bool) {
        return robotRules[rule];
    }
}
