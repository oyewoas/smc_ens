// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/Ens.sol";

contract EnsTest is Test {
    Ens public ens;

    // Test addresses
    address public owner;
    address public user1;
    address public user2;
    address public user3;

    // Test data
    string constant NAME1 = "alice";
    string constant NAME2 = "bob";
    string constant NAME3 = "charlie";
    string constant LONG_NAME = "this_is_a_very_long_name_that_exceeds_the_maximum_allowed_length_of_64_characters";
    string constant EMPTY_NAME = "";

    string constant IMAGE_HASH1 = "QmX7eqtVQvXGHjQQKHfPz9LqAWWqGqRzY2NrF3kZ8vQxU5";
    string constant IMAGE_HASH2 = "QmY8frtWRvYHJkRRLKHgQx3NsG4tK9mZ7vQxU5kZ8vQxU6";
    string constant EMPTY_IMAGE_HASH = "";

    event NameRegistered(string indexed name, address indexed owner, string imageHash);
    event NameUpdated(string indexed name, address indexed newAddress, string newImageHash);
    event NameTransferred(string indexed name, address indexed oldOwner, address indexed newOwner);

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        vm.prank(owner);
        ens = new Ens();
    }

    // ============ REGISTRATION TESTS ============

    function testRegisterName() public {
        vm.prank(user1);

        // Expect the NameRegistered event
        vm.expectEmit(true, true, false, true);
        emit NameRegistered(NAME1, user1, IMAGE_HASH1);

        ens.registerName(NAME1, IMAGE_HASH1, user2);

        // Verify the name record
        (address recordOwner, address resolvedAddress, string memory imageHash, uint256 registrationTime) =
            ens.resolveName(NAME1);

        assertEq(recordOwner, user1);
        assertEq(resolvedAddress, user2);
        assertEq(imageHash, IMAGE_HASH1);
        assertGt(registrationTime, 0);

        // Verify owner's name list
        string[] memory ownedNames = ens.getNamesOwnedBy(user1);
        assertEq(ownedNames.length, 1);
        assertEq(ownedNames[0], NAME1);

        // Verify name is not available
        assertFalse(ens.isNameAvailable(NAME1));
    }

    function testRegisterMultipleNames() public {
        vm.startPrank(user1);

        ens.registerName(NAME1, IMAGE_HASH1, user1);
        ens.registerName(NAME2, IMAGE_HASH2, user2);

        vm.stopPrank();

        // Verify both names are owned by user1
        string[] memory ownedNames = ens.getNamesOwnedBy(user1);
        assertEq(ownedNames.length, 2);

        // Names can be in any order, so check both exist
        bool foundName1 = false;
        bool foundName2 = false;
        for (uint256 i = 0; i < ownedNames.length; i++) {
            if (keccak256(bytes(ownedNames[i])) == keccak256(bytes(NAME1))) {
                foundName1 = true;
            } else if (keccak256(bytes(ownedNames[i])) == keccak256(bytes(NAME2))) {
                foundName2 = true;
            }
        }
        assertTrue(foundName1 && foundName2);
    }

    // ============ REGISTRATION ERROR TESTS ============

    function testRegisterNameAlreadyRegistered() public {
        vm.prank(user1);
        ens.registerName(NAME1, IMAGE_HASH1, user1);

        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(Ens.NameAlreadyRegistered.selector, NAME1));
        ens.registerName(NAME1, IMAGE_HASH2, user2);
    }

    function testRegisterNameEmpty() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ens.NameEmpty.selector));
        ens.registerName(EMPTY_NAME, IMAGE_HASH1, user1);
    }

    function testRegisterNameTooLong() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ens.NameTooLong.selector, LONG_NAME));
        ens.registerName(LONG_NAME, IMAGE_HASH1, user1);
    }

    function testRegisterNameInvalidAddress() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ens.InvalidAddress.selector, address(0)));
        ens.registerName(NAME1, IMAGE_HASH1, address(0));
    }

    function testRegisterNameInvalidImageHash() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ens.InvalidImageHash.selector, EMPTY_IMAGE_HASH));
        ens.registerName(NAME1, EMPTY_IMAGE_HASH, user1);
    }

    // ============ UPDATE ADDRESS TESTS ============

    function testUpdateAddress() public {
        vm.prank(user1);
        ens.registerName(NAME1, IMAGE_HASH1, user1);

        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit NameUpdated(NAME1, user2, IMAGE_HASH1);

        ens.updateAddress(NAME1, user2);

        (, address resolvedAddress,,) = ens.resolveName(NAME1);
        assertEq(resolvedAddress, user2);
    }

    function testUpdateAddressNotOwner() public {
        vm.prank(user1);
        ens.registerName(NAME1, IMAGE_HASH1, user1);

        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(Ens.NotNameOwner.selector, NAME1, user2));
        ens.updateAddress(NAME1, user2);
    }

    function testUpdateAddressNameNotFound() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ens.NameNotFound.selector, NAME1));
        ens.updateAddress(NAME1, user1);
    }

    function testUpdateAddressInvalidAddress() public {
        vm.prank(user1);
        ens.registerName(NAME1, IMAGE_HASH1, user1);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ens.InvalidAddress.selector, address(0)));
        ens.updateAddress(NAME1, address(0));
    }

    // ============ UPDATE IMAGE TESTS ============

    function testUpdateImage() public {
        vm.prank(user1);
        ens.registerName(NAME1, IMAGE_HASH1, user1);

        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit NameUpdated(NAME1, user1, IMAGE_HASH2);

        ens.updateImage(NAME1, IMAGE_HASH2);

        (,, string memory imageHash,) = ens.resolveName(NAME1);
        assertEq(imageHash, IMAGE_HASH2);
    }

    function testUpdateImageNotOwner() public {
        vm.prank(user1);
        ens.registerName(NAME1, IMAGE_HASH1, user1);

        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(Ens.NotNameOwner.selector, NAME1, user2));
        ens.updateImage(NAME1, IMAGE_HASH2);
    }

    function testUpdateImageNameNotFound() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ens.NameNotFound.selector, NAME1));
        ens.updateImage(NAME1, IMAGE_HASH2);
    }

    function testUpdateImageInvalidHash() public {
        vm.prank(user1);
        ens.registerName(NAME1, IMAGE_HASH1, user1);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ens.InvalidImageHash.selector, EMPTY_IMAGE_HASH));
        ens.updateImage(NAME1, EMPTY_IMAGE_HASH);
    }

    // ============ TRANSFER TESTS ============

    function testTransferName() public {
        vm.prank(user1);
        ens.registerName(NAME1, IMAGE_HASH1, user1);

        vm.prank(user1);
        vm.expectEmit(true, true, true, false);
        emit NameTransferred(NAME1, user1, user2);

        ens.transferName(NAME1, user2);

        // Verify new ownership
        (address recordOwner,,,) = ens.resolveName(NAME1);
        assertEq(recordOwner, user2);

        // Verify name lists updated
        string[] memory user1Names = ens.getNamesOwnedBy(user1);
        string[] memory user2Names = ens.getNamesOwnedBy(user2);

        assertEq(user1Names.length, 0);
        assertEq(user2Names.length, 1);
        assertEq(user2Names[0], NAME1);
    }

    function testTransferNameMultiple() public {
        vm.startPrank(user1);
        ens.registerName(NAME1, IMAGE_HASH1, user1);
        ens.registerName(NAME2, IMAGE_HASH2, user1);
        ens.registerName(NAME3, IMAGE_HASH1, user1);
        vm.stopPrank();

        // Transfer middle name
        vm.prank(user1);
        ens.transferName(NAME2, user2);

        // Verify user1 still has 2 names
        string[] memory user1Names = ens.getNamesOwnedBy(user1);
        assertEq(user1Names.length, 2);

        // Verify user2 has 1 name
        string[] memory user2Names = ens.getNamesOwnedBy(user2);
        assertEq(user2Names.length, 1);
        assertEq(user2Names[0], NAME2);

        // Verify NAME2 is not in user1's list
        bool foundName2 = false;
        for (uint256 i = 0; i < user1Names.length; i++) {
            if (keccak256(bytes(user1Names[i])) == keccak256(bytes(NAME2))) {
                foundName2 = true;
                break;
            }
        }
        assertFalse(foundName2);
    }

    function testTransferNameNotOwner() public {
        vm.prank(user1);
        ens.registerName(NAME1, IMAGE_HASH1, user1);

        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(Ens.NotNameOwner.selector, NAME1, user2));
        ens.transferName(NAME1, user3);
    }

    function testTransferNameNotFound() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ens.NameNotFound.selector, NAME1));
        ens.transferName(NAME1, user2);
    }

    function testTransferNameInvalidAddress() public {
        vm.prank(user1);
        ens.registerName(NAME1, IMAGE_HASH1, user1);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ens.InvalidAddress.selector, address(0)));
        ens.transferName(NAME1, address(0));
    }

    function testTransferNameAlreadyOwner() public {
        vm.prank(user1);
        ens.registerName(NAME1, IMAGE_HASH1, user1);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ens.AlreadyOwner.selector, NAME1, user1));
        ens.transferName(NAME1, user1);
    }

    // ============ RESOLVE TESTS ============

    function testResolveName() public {
        vm.prank(user1);
        ens.registerName(NAME1, IMAGE_HASH1, user2);

        (address recordOwner, address resolvedAddress, string memory imageHash, uint256 registrationTime) =
            ens.resolveName(NAME1);

        assertEq(recordOwner, user1);
        assertEq(resolvedAddress, user2);
        assertEq(imageHash, IMAGE_HASH1);
        assertGt(registrationTime, 0);
        assertLe(registrationTime, block.timestamp);
    }

    function testResolveNameNotFound() public {
        vm.expectRevert(abi.encodeWithSelector(Ens.NameDoesNotExist.selector, NAME1));
        ens.resolveName(NAME1);
    }

    // ============ AVAILABILITY TESTS ============

    function testIsNameAvailable() public {
        assertTrue(ens.isNameAvailable(NAME1));

        vm.prank(user1);
        ens.registerName(NAME1, IMAGE_HASH1, user1);

        assertFalse(ens.isNameAvailable(NAME1));
    }

    // ============ OWNER LISTING TESTS ============

    function testGetNamesOwnedByEmpty() public view {
        string[] memory names = ens.getNamesOwnedBy(user1);
        assertEq(names.length, 0);
    }

    function testGetNamesOwnedBySingle() public {
        vm.prank(user1);
        ens.registerName(NAME1, IMAGE_HASH1, user1);

        string[] memory names = ens.getNamesOwnedBy(user1);
        assertEq(names.length, 1);
        assertEq(names[0], NAME1);
    }

    // ============ EDGE CASE TESTS ============

    function testNameWith64Characters() public {
        string memory maxLengthName = "a123456789b123456789c123456789d123456789e123456789f123456789abcd";

        vm.prank(user1);
        ens.registerName(maxLengthName, IMAGE_HASH1, user1);

        assertTrue(ens.isNameAvailable(maxLengthName) == false);
    }

    function testCaseSensitiveNames() public {
        string memory lowerName = "alice";
        string memory upperName = "ALICE";

        vm.startPrank(user1);
        ens.registerName(lowerName, IMAGE_HASH1, user1);
        ens.registerName(upperName, IMAGE_HASH2, user2); // Should work as different names
        vm.stopPrank();

        assertFalse(ens.isNameAvailable(lowerName));
        assertFalse(ens.isNameAvailable(upperName));
    }

    // ============ CONTRACT OWNER TESTS ============

    function testContractOwnerSet() public view {
        assertEq(ens.contractOwner(), owner);
    }

    // ============ COMPREHENSIVE WORKFLOW TESTS ============

    function testCompleteWorkflow() public {
        // Register name
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit NameRegistered(NAME1, user1, IMAGE_HASH1);
        ens.registerName(NAME1, IMAGE_HASH1, user1);

        // Update address
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit NameUpdated(NAME1, user2, IMAGE_HASH1);
        ens.updateAddress(NAME1, user2);

        // Update image
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit NameUpdated(NAME1, user2, IMAGE_HASH2);
        ens.updateImage(NAME1, IMAGE_HASH2);

        // Transfer ownership
        vm.prank(user1);
        vm.expectEmit(true, true, true, false);
        emit NameTransferred(NAME1, user1, user3);
        ens.transferName(NAME1, user3);

        // Verify final state
        (address recordOwner, address resolvedAddress, string memory imageHash,) = ens.resolveName(NAME1);

        assertEq(recordOwner, user3);
        assertEq(resolvedAddress, user2);
        assertEq(imageHash, IMAGE_HASH2);

        // Verify ownership lists
        assertEq(ens.getNamesOwnedBy(user1).length, 0);
        assertEq(ens.getNamesOwnedBy(user3).length, 1);
    }

    // ============ FUZZ TESTS ============

    function testFuzzRegisterValidName(string memory name, address targetAddress) public {
        vm.assume(bytes(name).length > 0 && bytes(name).length <= 64);
        vm.assume(targetAddress != address(0));

        vm.prank(user1);
        ens.registerName(name, IMAGE_HASH1, targetAddress);

        assertFalse(ens.isNameAvailable(name));
    }

    function testFuzzInvalidNameLength(string memory name) public {
        vm.assume(bytes(name).length == 0 || bytes(name).length > 64);

        vm.prank(user1);
        if (bytes(name).length == 0) {
            vm.expectRevert(abi.encodeWithSelector(Ens.NameEmpty.selector));
        } else {
            vm.expectRevert(abi.encodeWithSelector(Ens.NameTooLong.selector, name));
        }
        ens.registerName(name, IMAGE_HASH1, user1);
    }
}
