// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title IUniversalIdentity
/// @notice The IUniversalIdentity interface is used to manage the identity of robots.

interface IUniversalIdentity {
    /// @notice Adds a rule to the robot's identity, showing that the robot agrees to follow the rule.
    /// @param rule The dynamic byte array representing the rule that the robot agrees to follow.
    /// @dev The rule SHOULD come from the rule sets defined in the IUniversalCharter contract that the robot intends to
    /// join.
    /// @dev This function SHOULD be implemented by contracts to add the rules that the robot intends to follow.
    function addRule(bytes memory rule) external;

    /// @notice Removes a rule from the robot's identity.
    /// @param rule The dynamic byte array representing the rule that the robot no longer agrees to follow.
    /// @dev This function SHOULD be implemented by contracts to remove the rules that the robot does not intend to
    /// follow.
    function removeRule(bytes memory rule) external;

    /// @notice Checks if the robot complies with a specific rule.
    /// @param rule The rule to check.
    /// @return bool Returns true if the robot complies with the rule.
    /// @dev This function MUST be implemented by contracts for compliance verification.
    function checkCompliance(bytes memory rule) external view returns (bool);

    /// @dev Emitted when a rule is added to the robot's identity.
    event RuleAdded(bytes rule);

    /// @dev Emitted when a rule is removed from the robot's identity.
    event RuleRemoved(bytes rule);

    /// @dev Emitted when a charter is subscribed to.
    event SubscribedToCharter(address indexed charter);

    /// @dev Emitted when it is unsubscribed from a charter.
    event UnsubscribedFromCharter(address indexed charter);
}
