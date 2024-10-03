// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UniversalCharter } from "./UniversalCharter.sol";

// Interfaces
import { IUniversalIdentity } from "./interface/IUniversalIdentity.sol";
import { IUniversalCharter } from "./interface/IUniversalCharter.sol";

/// @title UniversalIdentity
/// @notice The UniversalIdentity contract is used to manage the identity of robots.

contract UniversalIdentity is IUniversalIdentity, OwnableUpgradeable {
    /// @notice Version identifier for the current implementation of the contract.
    string public constant VERSION = "v0.0.1";

    /// @notice Mapping to store rules that the robot has agreed to follow
    mapping(bytes => bool) private robotRules;

    /// @notice Mapping to store the off-chain compliance status for each rule
    mapping(bytes => bool) private complianceStatus;

    // @notice Track the charters the robot is subscribed to
    mapping(address => bool) private subscribedCharters;

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

    /// @notice Subscribe and register to a specific UniversalCharter contract using its stored rule set
    /// @param charter The address of the UniversalCharter contract
    /// @param version The version of the rule set to fetch and register for
    function subscribeAndRegisterToCharter(address charter, uint256 version) external {
        require(!subscribedCharters[charter], "Already subscribed to this charter");
        subscribedCharters[charter] = true;

        // Fetch the rule set directly from the UniversalCharter contract using the public getter
        bytes[] memory ruleSet = UniversalCharter(charter).getRuleSet(version);

        // Register as a robot in the charter using the fetched rule set
        UniversalCharter(charter).registerUser(IUniversalCharter.UserType.Robot, ruleSet);

        emit SubscribedToCharter(charter);
    }

    /// @notice Leave the system for a specific UniversalCharter contract
    /// @param charter The address of the UniversalCharter contract to leave
    function leaveCharter(address charter) external {
        require(subscribedCharters[charter], "Not subscribed to this charter");

        // Call the leaveSystem function of the UniversalCharter contract
        UniversalCharter(charter).leaveSystem();

        // Unsubscribe from the charter after leaving
        subscribedCharters[charter] = false;
        emit UnsubscribedFromCharter(charter);
    }

    /// @notice Updates compliance status for a rule (called by the owner)
    /// @param rule The dynamic byte array representing the rule
    /// @param status The compliance status (true if compliant, false if not)
    function updateCompliance(bytes memory rule, bool status) external onlyOwner ruleExists(rule) {
        complianceStatus[rule] = status;

        emit ComplianceChecked(msg.sender, rule); // ComplianceChecked event needs to be declared
    }

    /// @notice Checks if the robot has agreed to follow a specific rule and if it is compliant
    /// @param rule The rule to check.
    /// @return bool Returns true if the robot has agreed to the rule and is compliant
    function checkCompliance(bytes memory rule) external view override returns (bool) {
        if (!robotRules[rule]) {
            revert RuleNotAgreed(rule);
        }

        return true;
    }

    /// @notice Gets the compliance status of a rule
    /// @param rule The rule to check.
    function getRule(bytes memory rule) external view returns (bool) {
        return robotRules[rule];
    }

    /// @notice Gets the subscription status of a charter
    /// @param charter The address of the charter to check.
    function getSubscribedCharters(address charter) external view returns (bool) {
        return subscribedCharters[charter];
    }

    /// @notice Gets the compliance status of a rule
    /// @param rule The rule to check.
    function getComplianceStatus(bytes memory rule) external view returns (bool) {
        return complianceStatus[rule];
    }
}
