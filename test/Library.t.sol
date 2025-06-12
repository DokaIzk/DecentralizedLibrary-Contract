// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import {Test, console} from "forge-std/Test.sol";
import {Library} from "../src/Library.sol";

contract LibraryTestContract is Test {
    Library Lib;
    address librarian;
    address user1;
    address user2;

    function setUp() public {
        Lib = new Library();
        librarian = address(this);
        user1 = address(0x123);
        user2 = address(0x124);
    }

    function testAddBook() public {
        vm.prank(librarian);
        Lib.addBook("The White Wizard", "Tade Adegbindin", 5);

        (,, string memory author, uint256 copies) = Lib.books(0);
        assertEq(author, "Tade Adegbindin");
        assertEq(copies, 5);
    }

    function testUserAddBook() public {
        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(Library.NotLibrarian.selector, "Only The Librarian Can Call This Function")
        );
        Lib.addBook("Htiler: The Legend", "Emmanuel Nzuebe", 1);
    }

    function testAddBookZeroCopies() public {
        vm.expectRevert(abi.encodeWithSelector(Library.InvalidCopies.selector, "Must Have At Least 1 Copy"));
        Lib.addBook("Animal Farm", "George Orwell", 0);
    }

    function testBorrowAndReturnBook() public {
        Lib.addBook("The Art of War", "Sun Tzu", 3);

        vm.prank(user1);
        Lib.borrowBook(0);
        uint256 available = Lib.getAvailableCopies(0);
        assertEq(available, 2);

        vm.prank(user1);
        Lib.returnBook(0);
        available = Lib.getAvailableCopies(0);
        assertEq(available, 3);
    }

    function testBorrowBookTwice() public {
        Lib.addBook("The White Wizard", "Tade Adegbindin", 5);

        vm.prank(user1);
        Lib.borrowBook(0);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Library.AlreadyBorrowed.selector, "You Already Borrowed This Book"));
        Lib.borrowBook(0);
    }

    function testReturnBookWithoutBorrowing() public {
        Lib.addBook("The Subtle Art of Not Giving a F*ck", "Mark Manson", 1);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Library.NotBorrowedYet.selector, "You Haven't Borrowed This Book"));
        Lib.returnBook(0);
    }

    function testGetUserBorrowedBooks() public {
        Lib.addBook("Animal Farm", "George Orwell", 5);
        Lib.addBook("Htiler: The Legend", "Emmanuel Nzuebe", 30);
        Lib.addBook("The Subtle Art of Not Giving a F*ck", "Mark Manson", 1);

        vm.prank(user1);
        Lib.borrowBook(0);

        vm.prank(user1);
        Lib.borrowBook(1);

        vm.prank(user1);
        Lib.borrowBook(2);

        uint256[] memory borrowed = Lib.getUserBorrowedBooks(user1);
        assertEq(borrowed.length, 3);
    }
}
