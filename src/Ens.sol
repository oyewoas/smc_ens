// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Ens {
    // Events
    event NameRegistered(string indexed name, address indexed owner, string imageHash);
    event NameUpdated(string indexed name, address indexed newAddress, string newImageHash);
    event NameTransferred(string indexed name, address indexed oldOwner, address indexed newOwner);

    // Errors
    error NameAlreadyRegistered(string name);
    error NameNotFound(string name);
    error NotNameOwner(string name, address caller);
    error InvalidAddress(address addr);
    error InvalidImageHash(string imageHash);
    error NameTooLong(string name);
    error NameEmpty();
    error Unauthorized(address caller);
    error NameDoesNotExist(string name);
    error AlreadyOwner(string name, address owner);

    // Structs
    struct NameRecord {
        address owner;
        address resolvedAddress;
        string imageHash; // IPFS hash from Pinata
        uint256 registrationTime;
        bool exists;
    }

    // State variables
    mapping(string => NameRecord) public nameRecords;
    mapping(address => string[]) public ownerToNames;

    address public contractOwner;

    // Modifiers
    modifier onlyNameOwner(string memory name) {
        if (!nameRecords[name].exists) revert NameNotFound(name);
        if (nameRecords[name].owner != msg.sender) revert NotNameOwner(name, msg.sender);
        _;
    }

    modifier onlyContractOwner() {
        if (msg.sender != contractOwner) revert Unauthorized(msg.sender);
        _;
    }

    modifier validName(string memory name) {
        if (bytes(name).length == 0) revert NameEmpty();
        if (bytes(name).length > 64) revert NameTooLong(name);
        _;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    /**
     * @dev Register a new name with image and address
     * @param name The name to register (e.g., "alice")
     * @param imageHash IPFS hash of the image from Pinata
     * @param targetAddress The Ethereum address to resolve to
     */
    function registerName(string memory name, string memory imageHash, address targetAddress)
        external
        validName(name)
    {
        if (nameRecords[name].exists) revert NameAlreadyRegistered(name);
        if (targetAddress == address(0)) revert InvalidAddress(targetAddress);
        if (bytes(imageHash).length == 0) revert InvalidImageHash(imageHash);

        // Create the name record
        nameRecords[name] = NameRecord({
            owner: msg.sender,
            resolvedAddress: targetAddress,
            imageHash: imageHash,
            registrationTime: block.timestamp,
            exists: true
        });

        // Add to owner's list of names
        ownerToNames[msg.sender].push(name);

        emit NameRegistered(name, msg.sender, imageHash);
    }

    /**
     * @dev Update the resolved address for a name
     * @param name The name to update
     * @param newAddress The new address to resolve to
     */
    function updateAddress(string memory name, address newAddress) external onlyNameOwner(name) {
        if (newAddress == address(0)) revert InvalidAddress(newAddress);

        nameRecords[name].resolvedAddress = newAddress;
        emit NameUpdated(name, newAddress, nameRecords[name].imageHash);
    }

    /**
     * @dev Update the image hash for a name
     * @param name The name to update
     * @param newImageHash The new IPFS hash
     */
    function updateImage(string memory name, string memory newImageHash) external onlyNameOwner(name) {
        if (bytes(newImageHash).length == 0) revert InvalidImageHash(newImageHash);

        nameRecords[name].imageHash = newImageHash;
        emit NameUpdated(name, nameRecords[name].resolvedAddress, newImageHash);
    }

    /**
     * @dev Transfer ownership of a name
     * @param name The name to transfer
     * @param newOwner The new owner address
     */
    function transferName(string memory name, address newOwner) external onlyNameOwner(name) {
        if (newOwner == address(0)) revert InvalidAddress(newOwner);
        if (newOwner == nameRecords[name].owner) revert AlreadyOwner(name, newOwner);

        address oldOwner = nameRecords[name].owner;
        nameRecords[name].owner = newOwner;

        // Remove from old owner's list
        _removeNameFromOwner(oldOwner, name);

        // Add to new owner's list
        ownerToNames[newOwner].push(name);

        emit NameTransferred(name, oldOwner, newOwner);
    }

    /**
     * @dev Resolve a name to get all associated data
     * @param name The name to resolve
     * @return owner The owner of the name
     * @return resolvedAddress The address the name resolves to
     * @return imageHash The IPFS hash of the associated image
     * @return registrationTime When the name was registered
     */
    function resolveName(string memory name)
        external
        view
        returns (address owner, address resolvedAddress, string memory imageHash, uint256 registrationTime)
    {
        if (!nameRecords[name].exists) revert NameDoesNotExist(name);

        NameRecord memory record = nameRecords[name];
        return (record.owner, record.resolvedAddress, record.imageHash, record.registrationTime);
    }

    /**
     * @dev Check if a name is available for registration
     * @param name The name to check
     * @return available True if the name is available
     */
    function isNameAvailable(string memory name) external view returns (bool available) {
        return !nameRecords[name].exists;
    }

    /**
     * @dev Get all names owned by an address
     * @param owner The owner address
     * @return names Array of names owned by the address
     */
    function getNamesOwnedBy(address owner) external view returns (string[] memory names) {
        return ownerToNames[owner];
    }

    /**
     * @dev Internal function to remove a name from an owner's list
     * @param owner The owner address
     * @param name The name to remove
     */
    function _removeNameFromOwner(address owner, string memory name) internal {
        string[] storage names = ownerToNames[owner];
        for (uint256 i = 0; i < names.length; i++) {
            if (keccak256(bytes(names[i])) == keccak256(bytes(name))) {
                names[i] = names[names.length - 1];
                names.pop();
                break;
            }
        }
    }
}
