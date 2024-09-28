// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SystemConfig } from "./SystemConfig.sol";

// Interfaces
import { IUniversalCharter } from "./interface/IUniversalCharter.sol";
import { IUniversalIdentity } from "./interface/IUniversalIdentity.sol";

/// @title UniversalCharter
/// @notice The UniversalCharter contract is used to manage the registration and compliance of users.

contract UniversalCharter is IUniversalCharter, OwnableUpgradeable {
    /// @notice Struct to store information about a registered user
    struct UserInfo {
        bool isRegistered;
        UserType userType;
        uint256 ruleSetVersion; // Rule set version the user is following
    }

    /// @notice Mapping to store registered users
    mapping(address => UserInfo) private users;

    /// @notice Mapping to store rule sets by version number
    mapping(uint256 => bytes[]) private ruleSets;

    /// @notice Mapping to track the rule set hash and its corresponding version
    mapping(bytes32 => uint256) private ruleSetVersions;

    /// @notice Version identifier for the current implementation of the contract.
    string public constant VERSION = "v0.0.1";

    /// @notice Variable to track the current version of the rule set
    uint256 private currentVersion;

    /// @notice Variable to store the address of the SystemConfig contract
    SystemConfig public systemConfig;

    /// @notice Error for when a method cannot be called when paused. This could be renamed
    ///         to `Paused` in the future, but it collides with the `Paused` event.
    error CallPaused();

    /// @notice Reverts when paused.
    modifier whenNotPaused() {
        if (paused()) revert CallPaused();
        _;
    }

    /// @notice Constucts the UniversalCharter contract.
    constructor() {
        initialize({ _owner: address(0xdEaD), _systemConfig: address(0xdEaD) });
    }

    /// @dev Initializer function
    function initialize(address _owner, address _systemConfig) public initializer {
        __Ownable_init();
        transferOwnership(_owner);
        systemConfig = SystemConfig(_systemConfig);
    }

    /// @notice Registers a user (either human or robot) by agreeing to a rule set
    /// @param user The address of the user joining the system (robot or human)
    /// @param userType The type of user: Human or Robot
    /// @param ruleSet The array of individual rules the user agrees to follow
    function registerUser(address user, UserType userType, bytes[] memory ruleSet) external override whenNotPaused {
        require(!users[user].isRegistered, "User already registered");

        // Hash the rule set to find the corresponding version
        bytes32 ruleSetHash = keccak256(abi.encode(ruleSet));
        uint256 version = ruleSetVersions[ruleSetHash];
        require(version > 0, "Invalid or unregistered rule set");

        // For robots, ensure compliance with each rule via the UniversalIdentity contract
        if (userType == UserType.Robot) {
            require(_checkRobotCompliance(user, version), "Robot not compliant with rule set");
        }

        // Register the user with the versioned rule set
        users[user] = UserInfo({ isRegistered: true, userType: userType, ruleSetVersion: version });

        emit UserRegistered(user, userType, ruleSet);
    }

    /// @notice Allows a user (human or robot) to leave the system after passing compliance checks
    function leaveSystem() external override whenNotPaused {
        require(users[msg.sender].isRegistered, "User not registered");

        UserInfo memory userInfo = users[msg.sender];

        // For robots, verify compliance with all rules in the rule set
        uint256 version = userInfo.ruleSetVersion;
        if (userInfo.userType == UserType.Robot) {
            require(_checkRobotCompliance(msg.sender, version), "Robot not compliant with rule set");
        }

        userInfo = UserInfo({ isRegistered: false, userType: UserType.Human, ruleSetVersion: 0 });

        emit UserLeft(msg.sender);
    }

    /// @notice Checks if a user complies with their registered rule set
    /// @param user The address of the user (human or robot)
    /// @param ruleSet The array of individual rules to verify
    /// @return bool Returns true if the user complies with the given rule set
    function checkCompliance(address user, bytes[] memory ruleSet) external view override returns (bool) {
        require(users[user].isRegistered, "User not registered");

        // Hash the provided rule set to find the corresponding version
        bytes32 ruleSetHash = keccak256(abi.encode(ruleSet));
        uint256 version = ruleSetVersions[ruleSetHash];
        require(version > 0, "Invalid or unregistered rule set");
        require(users[user].ruleSetVersion == version, "Rule set version mismatch");

        // For robots, check compliance with each rule in the UniversalIdentity contract
        if (users[user].userType == UserType.Robot) {
            return _checkRobotCompliance(user, version);
        }

        // If the user is human, compliance is assumed for now (can be extended)
        return true;
    }

    /// @notice Internal function to check compliance for robots with their rule set version
    /// @dev This function will revert if the robot is not compliant with any rule. Returns true for view purposes.
    /// @param robotAddress The address of the robot
    /// @param version The version of the rule set to verify compliance with
    /// @return bool Returns true if the robot is compliant with all the rules in the rule set
    function _checkRobotCompliance(address robotAddress, uint256 version) internal view returns (bool) {
        IUniversalIdentity robot = IUniversalIdentity(robotAddress);
        bytes[] memory rules = ruleSets[version];

        for (uint256 i = 0; i < rules.length; i++) {
            if (!robot.checkCompliance(rules[i])) {
                return false;
            }
        }

        return true;
    }

    /// @notice Updates or defines a new rule set version.
    /// @param newRuleSet The array of new individual rules.
    /// @dev This function SHOULD be restricted to authorized users (e.g., contract owner).
    function updateRuleSet(bytes[] memory newRuleSet) external whenNotPaused onlyOwner {
        require(newRuleSet.length > 0, "Cannot update to an empty rule set");

        // Hash the new rule set and ensure it's not already registered
        bytes32 ruleSetHash = keccak256(abi.encode(newRuleSet));
        require(ruleSetVersions[ruleSetHash] == 0, "Rule set already registered");

        // Increment the version and store the new rule set
        currentVersion += 1;
        ruleSets[currentVersion] = newRuleSet;
        ruleSetVersions[ruleSetHash] = currentVersion;

        emit RuleSetUpdated(newRuleSet, msg.sender);
    }

    /// @notice Getter for the latest version of the rule set.
    function getLatestRuleSetVersion() external view returns (uint256) {
        return currentVersion;
    }

    /// @notice Get the rule set for a specific version.
    /// @param version The version of the rule set to retrieve.
    function getRuleSet(uint256 version) external view returns (bytes[] memory) {
        return ruleSets[version];
    }

    /// @notice Get the version number for a specific rule set.
    /// @param ruleSet The hash of the rule set to retrieve the version for.
    function getRuleSetVersion(bytes32 ruleSet) external view returns (uint256) {
        return ruleSetVersions[ruleSet];
    }

    function getUserInfo(address user) external view returns (UserInfo memory) {
        return users[user];
    }

    /// @notice Getter for the current paused status.
    /// @return paused_ Whether or not the contract is paused.
    function paused() public view returns (bool paused_) {
        paused_ = systemConfig.paused();
    }
}
