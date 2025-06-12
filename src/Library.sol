// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

contract Library {
    address public Librarian;
    uint256 public nextBookId;

    error NotLibrarian(string reason);
    error InvalidCopies(string reason);
    error BookDoesNotExist(string reason);
    error NoAvailableCopies(string reason);
    error AlreadyBorrowed(string reason);
    error NotBorrowedYet(string reason);

    struct Book {
        uint256 id;
        string title;
        string author;
        uint256 copies;
    }

    mapping(uint256 => Book) public books;
    mapping(address => mapping(uint256 => bool)) public hasBorrowed;
    mapping(address => uint256[]) private borrowedBooks;

    event BookAdded(uint256 indexed ID, string title, string author, uint256 copies);
    event BookBorrowed(address indexed user, uint256 indexed ID);
    event BookReturned(address indexed user, uint256 indexed ID);

    constructor() {
        Librarian = msg.sender;
    }

    modifier OnlyLibrarian() {
        if (msg.sender != Librarian) revert NotLibrarian("Only The Librarian Can Call This Function");
        _;
    }

    modifier bookExists(uint256 ID) {
        if (ID >= nextBookId) revert BookDoesNotExist("Book Not Found");
        _;
    }

    function addBook(string calldata _title, string calldata _author, uint256 _copies) external OnlyLibrarian {
        if (_copies == 0) revert InvalidCopies("Must Have At Least 1 Copy");

        books[nextBookId] = Book({id: nextBookId, title: _title, author: _author, copies: _copies});

        emit BookAdded(nextBookId, _title, _author, _copies);

        nextBookId++;
    }

    function borrowBook(uint256 ID) external bookExists(ID) {
        Book storage book = books[ID];

        if (book.copies == 0) revert NoAvailableCopies("No Copies Available To Borrow");
        if (hasBorrowed[msg.sender][ID]) revert AlreadyBorrowed("You Already Borrowed This Book");

        book.copies--;
        hasBorrowed[msg.sender][ID] = true;
        borrowedBooks[msg.sender].push(ID);

        emit BookBorrowed(msg.sender, ID);
    }

    function returnBook(uint256 ID) external bookExists(ID) {
        if (!hasBorrowed[msg.sender][ID]) revert NotBorrowedYet("You Haven't Borrowed This Book");

        Book storage book = books[ID];
        book.copies++;
        hasBorrowed[msg.sender][ID] = false;

        uint256[] storage borrowed = borrowedBooks[msg.sender];

        for (uint256 i = 0; i < borrowed.length; i++) {
            if (borrowed[i] == ID) {
                borrowed[i] = borrowed[borrowed.length - 1];
                borrowed.pop();
                break;
            }
        }

        emit BookReturned(msg.sender, ID);
    }

    function getBook(uint256 ID) external view bookExists(ID) returns (Book memory) {
        return books[ID];
    }

    function getAvailableCopies(uint256 ID) external view bookExists(ID) returns (uint256) {
        return books[ID].copies;
    }

    function getAllBooks() external view returns (Book[] memory) {
        Book[] memory all = new Book[](nextBookId);
        for (uint256 i = 0; i < nextBookId; i++) {
            all[i] = books[i];
        }
        return all;
    }

    function getUserBorrowedBooks(address user) external view returns (uint256[] memory) {
        return borrowedBooks[user];
    }
}
