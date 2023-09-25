import ballerina/grpc;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/time;
import ballerina/sql;

configurable string USER = "root";
configurable string PASSWORD = "PHW#84#jeor";
configurable string HOST = "localhost";
configurable int PORT = 3306;
configurable string DATABASE = "library";

final mysql:Client mySQLClient = check new (
    host = "localhost", user = "root", password = "PHW#84#jeor", port = 3306, database = "library"
);

listener grpc:Listener ep = new (9090);

@grpc:Descriptor {value: LIBRARY_DESC}
service "Library" on ep {

    remote function addBook(Book book) returns string|error {
        string insertQuery = string `INSERT INTO books (bookISBN, bookTitle, author, location) VALUES (${book.isbn}, ${book.title}, ${book.author}, ${book.location})`;
        var insertParams = [book.isbn, book.title, book.author, book.location];

        sql:ParameterizedQuery query = `INSERT INTO books (bookISBN, bookTitle, author, location) VALUES (${book.isbn}, ${book.title}, ${book.author}, ${book.location})`;

        var insertResult = check mySQLClient->execute(query);

        if (insertResult is int) {
            if (insertResult > 0) {
                return "Book added successfully";
            } else {
                return "Failed to add the book";
            }
        } else {
            return "Failed to add the book: " + insertResult.toString();
        }
    }

    remote function updateBook(Book value) returns string|error {
        string updateQuery = "UPDATE books SET title = ?, author = ? WHERE isbn = ?";
        var updateParams = [value.title, value.author, value.isbn];

        sql:ParameterizedQuery query = `UPDATE books SET title = ${value.title}, author = ${value.author}  WHERE isbn = ${value.isbn}`;

        var updateResult = check mySQLClient->execute(query);

        if (updateResult is int) {
            if (updateResult > 0) {
                return "Book updated successfully";
            } else {
                return "No book found with the given ISBN";
            }
        } else {
            return "Failed to update the book: " + updateResult.toString();
        }

    }
    remote function removeBook(string value) returns Book|error {
        string deleteQuery = "DELETE FROM books WHERE isbn = ?";
        var deleteParams = [value];

        sql:ParameterizedQuery query = `DELETE FROM books WHERE isbn = ${value}`;

        var deleteResult = check mySQLClient->execute(query);

        Book book = {};

        if (deleteResult is int) {
            if (deleteResult > 0) {
                return book;
            } else {
                return error("No book found with the given ISBN");
            }
        } else {
            return error("Failed to remove the book: " + deleteResult.toString());
        }

    }
    remote function locateBook(locBook value) returns Book|error {
        string selectQuery = "SELECT title, author, isbn FROM books WHERE isbn = ?";
        var selectParams = [value.book_isbn];

        sql:ParameterizedQuery query = `SELECT title, author, isbn FROM books WHERE isbn = ${value.book_isbn}`;

        var selectResult = mySQLClient->query(query, Book);

        if (selectResult is Book) {
            if (selectResult.lenght == 0) {
                return error("No book found with the given ISBN");
            } else {
                map<string>? resultRow = selectResult[0];
                // if (resultRow != null) {
                //     return {
                //         title: resultRow["title"] as string,
                //         author: resultRow["author"] as string,
                //         isbn: resultRow["isbn"] as string
                //     };
                // }

                Book book = {
                    title: selectResult[0].title,
                    author: selectResult[0].author,
                    isbn: selectResult[0].isbn
                };
            }
        } else {
            return error("Failed to locate the book: " + selectResult.toString());
        }

    }
    remote function borrowBook(Request value) returns string|error {
        // var isBookAvailable = checkIsBookAvailable(value.isbn);
        var isBookAvailable = true;

        if (isBookAvailable) {
            var borrowQuery = "INSERT INTO borrow_history (user_id, book_isbn, borrow_date) VALUES (?, ?, ?)";
            //var borrowParams = [value.userId, value.book_isbn, time:currentTime()];

            sql:ParameterizedQuery query = `INSERT INTO borrow_history (user_id, book_isbn, borrow_date) VALUES (${value.user_id}, ${value.book_isbn}, ${time:utcNow()})`;

            var borrowResult = check mySQLClient->execute(query);

            if (borrowResult is int) {
                //var updateQuery = "UPDATE books SET is_available = FALSE WHERE isbn = ?";
                //var updateParams = [value.isbn];

                sql:ParameterizedQuery updateQuery = `UPDATE books SET is_available = FALSE WHERE isbn = ${value.book_isbn}`;

                var updateResult = check mySQLClient->execute(updateQuery);

                if (updateResult is int && updateResult.length() > 0) {
                    return "Book borrowed successfully";
                } else {
                    return "Failed to update book availability status";
                }
            } else {
                return "Failed to record borrow history: " + borrowResult.toString();
            }
        } else {
            return "Book is not available for borrowing";
        }
    }
    remote function createUsers(stream<User, grpc:Error?> clientStream) returns string|error {
        do {
            while(true){
            var user = check clientStream.next();

            if (user is User) {
                var insertQuery = "INSERT INTO users (username, email) VALUES (?, ?)";
                var insertParams = [user.username, user.email];

                sql:ParameterizedQuery query = `INSERT INTO users (username, email) VALUES (${user.username}, ${user.email})`;

                var insertResult = check mySQLClient->execute(query);

                if (insertResult is int) {
                    return "Failed to insert user: " + insertResult.reason();
                }
            } else {
                break;
            }
            }

            return "Users created successfully";
        } on fail var varName {
            return error("Error while receiving user data from the client: "         + varName.message());
        }
        
    }

    remote function listAvailableBooks() returns stream<Book, error?>|error {
        string selectQuery = "SELECT title, author, isbn FROM books WHERE is_available = TRUE";

        sql:ParameterizedQuery query = `SELECT title, author, isbn FROM books WHERE is_available = TRUE`;
        var selectResult =  mySQLClient->query(query, Book);

        if (selectResult is Book)  {
            // Define a stream to send the available books to the client
            stream<Book, error?> availableBooksStream=new;
            Book[] books = [];

            foreach var item in selectResult {
                Book book = {
                    title: item.title,
                    author: item.author,
                    isbn: item.isbn
                };

                books.push(book);
            }

            return books.toStream();
        } else {
            return error("Failed to retrieve available books: " + selectResult.toString());
        }
    }
}

