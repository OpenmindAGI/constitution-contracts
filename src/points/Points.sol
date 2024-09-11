// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// @title Points
/// @notice The Points contract is used to manage the points system.

contract Points is OwnableUpgradeable {
    /// @notice A struct representing a quest.
    /// @param id The ID of the quest.
    /// @param name The name of the quest.
    /// @param startTime The start time of the quest.
    /// @param endTime The end time of the quest.
    struct Quest {
        uint256 id;
        string name;
        uint256 startTime;
        uint256 endTime;
    }

    /// @notice A struct representing a submission.
    /// @param questId The ID of the quest.
    /// @param user The user that submitted the quest.
    /// @param timestamp The timestamp of the submission.
    /// @param points The points awarded for the submission.
    struct Submission {
        uint256 questId;
        bytes32 user;
        uint256 timestamp;
        uint256 points;
    }

    /// @notice Version identifier for the current implementation of the contract.
    string public constant VERSION = "v0.0.1";

    /// @notice The storage slot that holds the system configuration.
    bytes32 public constant SYSTEM_CONFIG_SLOT = keccak256("Points.SystemConfig");

    /// @notice The operator of the Points contract.
    bytes32 public constant OPERATOR_SLOT = keccak256("Points.Operator");

    /// @notice A mapping of user addresses to whether they are registered.
    mapping(bytes32 => bool) public registeredUsers;

    /// @notice A mapping of user addresses to their points balance.
    mapping(bytes32 => uint256) private points;

    /// @notice A mapping of quest ID to quest.
    mapping(uint256 => Quest) private quests;

    /// @notice A mapping of user address to their submissions.
    mapping(bytes32 => mapping(uint256 => Submission)) private submissions;

    /// @notice An event that is emitted each time a user is registered.
    /// @param user The user that was registered.
    event RegisteredUser(bytes32 user);

    /// @notice An event that is emitted each time a quest is registered.
    /// @param questId The ID of the quest.
    /// @param name The name of the quest.
    /// @param startTime The start time of the quest.
    /// @param endTime The end time of the quest.
    event RegisteredQuest(uint256 questId, string name, uint256 startTime, uint256 endTime);

    /// @notice An event that is emitted each time a quest is submitted.
    /// @param user The user that submitted the quest.
    /// @param questId The ID of the quest.
    /// @param timestamp The timestamp of the submission.
    event SubmittedQuest(bytes32 user, uint256 questId, uint256 timestamp);

    /// @notice An event that is emitted each time points are added to a user's balance.
    /// @param user The user that points were added to.
    /// @param quest The quest that points were added for.
    /// @param amount The amount of points that were added.
    event PointsAdded(bytes32 user, uint256 quest, uint256 amount);

    /// @notice An event that is emitted each time points are subtracted from a user's balance.
    /// @param user The user that points were subtracted from.
    /// @param amount The amount of points that were subtracted.
    event PointsSubtracted(bytes32 user, uint256 amount);

    /// @notice Modifier to restrict access to the operator.
    modifier onlyOperator() {
        require(msg.sender == operator(), "Points: caller is not the operator");
        _;
    }

    /// @notice Constucts the Points contract.
    constructor() {
        initialize({ _owner: address(0xdEaD), _operator: address(0xdEaD), _systemConfig: address(0xdEaD) });
    }

    /// @notice Initializes the Points contract.
    function initialize(address _owner, address _operator, address _systemConfig) public initializer {
        __Ownable_init();
        transferOwnership(_owner);

        _setOperator(_operator);
        _setSystemConfig(_systemConfig);
    }

    /// @notice A function to register a quest.
    /// @param _questId The ID of the quest.
    /// @param _name The name of the quest.
    /// @param _startTime The start time of the quest.
    /// @param _endTime The end time of the quest.
    function registerQuest(
        uint256 _questId,
        string memory _name,
        uint256 _startTime,
        uint256 _endTime
    )
        public
        onlyOperator
    {
        require(quests[_questId].id == 0, "Points: quest already registered");
        quests[_questId] = Quest({ id: _questId, name: _name, startTime: _startTime, endTime: _endTime });

        emit RegisteredQuest(_questId, _name, _startTime, _endTime);
    }

    /// @notice A function to register a user.
    function registerUser(bytes32 _user) public onlyOperator {
        require(!registeredUsers[_user], "Points: user already registered");
        registeredUsers[_user] = true;

        emit RegisteredUser(_user);
    }

    /// @notice A function to submit a quest.
    function submitQuest(bytes32 _user, uint256 _quest) public onlyOperator {
        require(quests[_quest].id != 0, "Points: quest not registered");
        require(quests[_quest].startTime <= block.timestamp, "Points: quest not started");
        require(quests[_quest].endTime >= block.timestamp, "Points: quest ended");

        require(registeredUsers[_user], "Points: user not registered");

        require(submissions[_user][_quest].questId == 0, "Points: quest already submitted");

        submissions[_user][_quest] = Submission({ questId: _quest, user: _user, timestamp: block.timestamp, points: 0 });

        emit SubmittedQuest(_user, _quest, block.timestamp);
    }

    /// @notice A function to add points to a user's balance.
    /// @param _user The user to add points to.

    /// @param _amount The amount of points to add.
    function addPoints(bytes32 _user, uint256 _quest, uint256 _amount) public onlyOperator {
        require(registeredUsers[_user], "Points: user not registered");

        require(submissions[_user][_quest].questId != 0, "Points: quest not submitted");

        submissions[_user][_quest].points = _amount;
        points[_user] += _amount;

        emit PointsAdded(_user, _quest, _amount);
    }

    /// @notice A function to subtract points from a user's balance.
    /// @param _user The user to subtract points from.
    /// @param _amount The amount of points to subtract.
    function subtractPoints(bytes32 _user, uint256 _amount) public onlyOperator {
        require(points[_user] >= _amount, "Points: insufficient balance");
        points[_user] -= _amount;

        emit PointsSubtracted(_user, _amount);
    }

    /// @notice A function to update the operator of the Points contract.
    /// @param _operator The address of the new operator.
    function setOperator(address _operator) public onlyOwner {
        _setOperator(_operator);
    }

    /// @notice A function to get the system configuration contract.
    function systemConfig() external view returns (address) {
        return _getAddress(SYSTEM_CONFIG_SLOT);
    }

    /// @notice A function to get the operator of the Points contract.
    function operator() public view returns (address) {
        return _getAddress(OPERATOR_SLOT);
    }

    /// @notice A function to add points to a user's balance.
    /// @param _user The user to add points to.
    function getPoints(string memory _user) public view returns (uint256) {
        return points[hash(_user)];
    }

    /// @notice A function to get the quest with the given ID.
    function getQuest(uint256 _questId) public view returns (Quest memory) {
        return quests[_questId];
    }

    /// @notice A function to get the submission for the given user and quest.
    function getSubmission(bytes32 _user, uint256 _quest) public view returns (Submission memory) {
        return submissions[_user][_quest];
    }

    /// @notice A function to add points to a user's balance.
    /// @param _systemConfig The address of the system configuration contract.
    function _setSystemConfig(address _systemConfig) internal {
        _setAddress(SYSTEM_CONFIG_SLOT, _systemConfig);
    }

    /// @notice A function to set the operator of the Points contract.
    /// @param _operator The address of the operator.
    function _setOperator(address _operator) internal {
        _setAddress(OPERATOR_SLOT, _operator);
    }

    /// @notice A function to get address
    /// @param _slot The slot to get the address from.
    function _getAddress(bytes32 _slot) internal view returns (address) {
        address addr;
        assembly {
            addr := sload(_slot)
        }
        return addr;
    }

    /// @notice A function to set address
    /// @param _slot The slot to set the address in.
    /// @param _addr The address to set.
    function _setAddress(bytes32 _slot, address _addr) internal {
        assembly {
            sstore(_slot, _addr)
        }
    }

    /// @notice a helper function to hash a string
    /// @param _input The string to hash
    function hash(string memory _input) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_input));
    }
}
