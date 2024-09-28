// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title IUniversalCharter
/// @notice The IUniversalCharter interface is used to manage the registration and compliance of users.

interface IUniversalCharter {
    // Define the user types as an enum.
    enum UserType {
        Human,
        Robot
    }

    /// @notice Registers a user (human or robot) to join the system by agreeing to a rule set.
    /// @param user Address of the user (either human or robot) joining the system.
    /// @param userType The type of user.
    /// @param ruleSet The array of individual rules the user agrees to follow.
    /// @dev This function MUST be implemented by contracts using this interface.
    /// @dev The implementing contract MUST ensure that the user complies with the specified rule set before registering
    /// them in the system by invoking `checkCompliance`.
    function registerUser(address user, UserType userType, bytes[] memory ruleSet) external;

    /// @notice Allows a user (human or robot) to leave the system
    /// @dev This function MUST be callable only by the user themselves (via `msg.sender`).
    /// @dev The implementing contract MUST ensure that the user has complied with all necessary rules before they can
    /// successfully leave the system by invoking `checkCompliance`.
    function leaveSystem() external;

    /// @notice Checks if the user (human or robot) complies with the system’s rules.
    /// @param user Address of the user (human or robot).
    /// @param ruleSet The array of individual rules to verify.
    /// @return bool Returns true if the user complies with the rule set.
    /// @dev This function SHOULD invoke the `checkCompliance` function of the user’s IUniversalIdentity contract to
    /// check for rules individually.
    /// @dev This function MUST be implemented by contracts for compliance verification.
    function checkCompliance(address user, bytes[] memory ruleSet) external view returns (bool);

    /// @notice Updates the rule set.
    /// @param newRuleSet The array of new individual rules replacing the existing ones.
    /// @dev This function SHOULD be restricted to authorized users (e.g., contract owner).
    function updateRuleSet(bytes[] memory newRuleSet) external;

    /// @dev Emitted when a user joins the system by agreeing to a set of rules.
    event UserRegistered(address indexed user, UserType userType, bytes[] ruleSet);

    /// @dev Emitted when a user successfully leaves the system after fulfilling obligations.
    event UserLeft(address indexed user);

    /// @dev Emitted when a user’s compliance with a rule set is verified.
    event ComplianceChecked(address indexed user, bytes[] ruleSet);

    /// @dev Emitted when a rule set is updated.
    event RuleSetUpdated(bytes[] newRuleSet, address updatedBy);
}
