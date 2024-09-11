// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// @title Constitution
/// @notice The Constitution contract is used to manage the constitution.

contract Constitution is OwnableUpgradeable {
    
    /// @notice A struct representing a law.
    /// @param id The ID of the law.
    /// @param name The name of the law.
    /// @param law The text of the law.
    /// @param firstBlock The first block the law is valid.
    /// @param lastBlock The last block the law is valid.
    struct Law {
        uint256 id;
        string name;
        string text;
        uint256 firstBlock;
        uint256 lastBlock;
    }

    Law[] public laws;

    uint256 public numberOfLaws;

    /// @notice Version identifier for the current implementation of the contract.
    string public constant VERSION = "v0.0.1";

    /// @notice The storage slot that holds the system configuration.
    bytes32 public constant SYSTEM_CONFIG_SLOT = keccak256("Constitution.SystemConfig");

    /// @notice The operator of the Constitution contract.
    bytes32 public constant OPERATOR_SLOT = keccak256("Constitution.Operator");

    /// @notice A mapping of user addresses to whether they are registered.
    mapping(bytes32 => bool) public registeredUsers;

    /// @notice A mapping of user addresses to their points balance.
    mapping(bytes32 => uint256) private points;

    /// @notice An event that is emitted each time a user is registered.
    /// @param user The user that was registered.
    event RegisteredUser(bytes32 user);

    /// @notice An event that is emitted each time a law is registered.
    /// @param id The ID of the law.
    /// @param name The name of the law.
    /// @param text The text of the law.
    /// @param firstBlock The first block the law is valid.
    /// @param lastBlock The last block the law is valid.
    event RegisteredLaw(uint256 id, string name, string text, uint256 firstBlock, uint256 lastBlock);

    /// @notice An event that is emitted when points are added to a user's balance.
    /// @param user The user that points were added to.
    /// @param amount The amount of points that were added.
    event PointsAdded(bytes32 user, uint256 amount);

    /// @notice An event that is emitted when points are subtracted from a user's balance.
    /// @param user The user that points were subtracted from.
    /// @param amount The amount of points that were subtracted.
    event PointsSubtracted(bytes32 user, uint256 amount);

    /// @notice Modifier to restrict access to the operator.
    modifier onlyOperator() {
        require(msg.sender == operator(), "Constitution: caller is not the operator");
        _;
    }

    /// @notice Constucts the Constitution contract.
    constructor() {
        initialize({ 
            _owner: address(0xdEaD), 
            _operator: address(0xdEaD), 
            _systemConfig: address(0xdEaD) 
        });
    }

    /// @notice Initializes the Constitution contract.
    function initialize(
        address _owner, 
        address _operator, 
        address _systemConfig
    ) public initializer {
        __Ownable_init();
        transferOwnership(_owner);
        _setOperator(_operator);
        _setSystemConfig(_systemConfig);
        numberOfLaws = 0;
    }

    /// @notice A function to register a new Law.
    /// @param _name The name of the law.
    /// @param _text The text of the law.
    /// @param _firstBlock The first block the law is valid.
    /// @param _lastBlock The last block the law is valid.
    function registerLaw(
        string memory _name,
        string memory _text,
        uint256 _firstBlock,
        uint256 _lastBlock
    )
        public
        onlyOperator
    {
        require(_firstBlock > block.timestamp, "Constitution: no retroactive laws");
        require(_lastBlock >= _firstBlock, "Constitution: a law must apply for at least 1 block");
        laws.push(Law(numberOfLaws, _name, _text, _firstBlock, _lastBlock));
        emit RegisteredLaw(numberOfLaws, _name, _text, _firstBlock, _lastBlock);
        numberOfLaws += 1;
    }

    //get all laws
    function GetAllLaws() view public returns(Law[] memory){
        return laws;
    }

    //get Nth law
    function GetNthLaw(uint x) view public returns(Law memory){
        return laws[x];
    }
    
    /// @notice A function to register a user.
    function registerUser(bytes32 _user) public onlyOperator {
        require(!registeredUsers[_user], "Constitution: user already registered");
        registeredUsers[_user] = true;
        emit RegisteredUser(_user);
    }

    /// @notice A function to add points to a user's balance.
    /// @param _user The user to add points to.
    /// @param _amount The amount of points to add.
    function addPoints(bytes32 _user, uint256 _amount) public onlyOperator {
        require(registeredUsers[_user], "Constitution: user not registered");
        points[_user] += _amount;
        emit PointsAdded(_user, _amount);
    }

    /// @notice A function to subtract points from a user's balance.
    /// @param _user The user to subtract points from.
    /// @param _amount The amount of points to subtract.
    function subtractPoints(bytes32 _user, uint256 _amount) public onlyOperator {
        require(points[_user] >= _amount, "Constitution: insufficient balance");
        points[_user] -= _amount;
        emit PointsSubtracted(_user, _amount);
    }

    /// @notice A function to update the operator of the Constitution contract.
    /// @param _operator The address of the new operator.
    function setOperator(address _operator) public onlyOwner {
        _setOperator(_operator);
    }

    /// @notice A function to get the system configuration contract.
    function systemConfig() external view returns (address) {
        return _getAddress(SYSTEM_CONFIG_SLOT);
    }

    /// @notice A function to get the operator of the Constitution contract.
    function operator() public view returns (address) {
        return _getAddress(OPERATOR_SLOT);
    }

    /// @notice A function to query a user's points balance.
    /// @param _user The user get the point's balance for.
    function getPoints(string memory _user) public view returns (uint256) {
        return points[hash(_user)];
    }

    /// @notice A function set the systemConfig address.
    /// @param _systemConfig The address of the system configuration contract.
    function _setSystemConfig(address _systemConfig) internal {
        _setAddress(SYSTEM_CONFIG_SLOT, _systemConfig);
    }

    /// @notice A function to set the operator of the Points contract.
    /// @param _operator The address of the operator.
    function _setOperator(address _operator) internal {
        _setAddress(OPERATOR_SLOT, _operator);
    }

    /// @notice A function to get the address stored in a specific slot
    /// @param _slot The slot to read the address from.
    function _getAddress(bytes32 _slot) internal view returns (address) {
        address addr;
        assembly {
            addr := sload(_slot)
        }
        return addr;
    }

    /// @notice A function to set the address is a specific slot
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
