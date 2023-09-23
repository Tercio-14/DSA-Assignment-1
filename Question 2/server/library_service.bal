
import ballerina/grpc;
import ballerina/sql;
@grpc:Descriptor {value: LIBRARY_DESC}
service "Library" on ep {

    remote function addBook(Book value) returns string|error {
        string insertQuery = "Insert into Books(title,author,isbn) Values (?,?,?)";
        var insertParams = [value.title, value.author, value.isbn];

    var addResult = check mySQLClient->executeInsert(insertQuery, insertParams);
    
    if (addResult is int) {
        return "Book added successfully";
    } else {
        return "Failed to add the book: " + addResult.reason();
    }
    
    }
    remote function updateBook(Book value) returns string|error {
         string updateQuery = "UPDATE books SET title = ?, author = ? WHERE isbn = ?";
    var updateParams = [value.title, value.author, value.isbn];

    var updateResult = check mySQLClient->executeUpdate(updateQuery, updateParams);
    
    if (updateResult is int) {
        if (updateResult > 0) {
            return "Book updated successfully";
        } else {
            return "No book found with the given ISBN";
        }
    } else {
        return "Failed to update the book: " + updateResult.reason();
    }

    }
    remote function removeBook(string value) returns Book|error {
        string deleteQuery = "DELETE FROM books WHERE isbn = ?";
    var deleteParams = [isbn];

    var deleteResult = check mySQLClient->executeUpdate(deleteQuery, deleteParams);
    
    if (deleteResult is int) {
        if (deleteResult > 0) {
            return "Book removed successfully";
        } else {
            return "No book found with the given ISBN";
        }
    } else {
        return "Failed to remove the book: " + deleteResult.reason();
    }

    }
    remote function locateBook(locBook value) returns Book|error {
            string selectQuery = "SELECT title, author, isbn FROM books WHERE isbn = ?";
    var selectParams = [isbn];

    var selectResult = check mySQLClient->select(selectQuery, selectParams);
    
    if (selectResult is table) {
        if (table:isEmpty(selectResult)) {
            return error("No book found with the given ISBN");
        } else {
            map<string>? resultRow = selectResult[0];
            if (resultRow != null) {
                return {
                    title: resultRow["title"] as string,
                    author: resultRow["author"] as string,
                    isbn: resultRow["isbn"] as string
                };
            }
        }
    } else {
        return error("Failed to locate the book: " + selectResult.reason());
    }

    }
    remote function borrowBook(Request value) returns string|error {
    var isBookAvailable = checkIsBookAvailable(value.isbn);

    if (isBookAvailable) {
        var borrowQuery = "INSERT INTO borrow_history (user_id, book_isbn, borrow_date) VALUES (?, ?, ?)";
        var borrowParams = [value.userId, value.isbn, currentDatetime()];

        var borrowResult = check mySQLClient->executeInsert(borrowQuery, borrowParams);

        if (borrowResult is int) {
            var updateQuery = "UPDATE books SET is_available = FALSE WHERE isbn = ?";
            var updateParams = [value.isbn];

            var updateResult = check mySQLClient->executeUpdate(updateQuery, updateParams);

            if (updateResult is int && updateResult > 0) {
                return "Book borrowed successfully";
            } else {
                return "Failed to update book availability status";
            }
        } else {
            return "Failed to record borrow history: " + borrowResult.reason();
        }
    } else {
        return "Book is not available for borrowing";
    }
    }
    remote function createUsers(stream<User, grpc:Error?> clientStream) returns string|error {
    try {
        while (true) {
            var user = check clientStream.getNext();

            if (user is User) {
                var insertQuery = "INSERT INTO users (username, email) VALUES (?, ?)";
                var insertParams = [user.username, user.email];

                var insertResult = check mySQLClient->executeInsert(insertQuery, insertParams);

                if (insertResult is not int) {
                    return "Failed to insert user: " + insertResult.reason();
                }
            } else {
                break;
            }
        }

        return "Users created successfully";
    } catch (grpc:Error e) {
        return "Error while receiving user data from the client: " + e.message();
    }
    }
    remote function listAvailableBooks() returns stream<Book, error?>|error {
            string selectQuery = "SELECT title, author, isbn FROM books WHERE is_available = TRUE";
    
    var selectResult = check mySQLClient->select(selectQuery);

    if (selectResult is table) {
        // Define a stream to send the available books to the client
        stream<Book, error?> availableBooksStream = new;

        foreach var row in selectResult {
            map<string>? resultRow = row;
            if (resultRow != null) {
                Book book = {
                    title: resultRow["title"] as string,
                    author: resultRow["author"] as string,
                    isbn: resultRow["isbn"] as string
                };
                // Send the book to the client
                _ = availableBooksStream.push(book);
            }
        }
        
        // Close the stream to indicate the end of data
        availableBooksStream.close();

        return availableBooksStream;
    } else {
        return error("Failed to retrieve available books: " + selectResult.reason());
    }
    }
}

