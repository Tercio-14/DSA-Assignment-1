import ballerina/io;
LibraryClient ep = check new ("http://localhost:9090");
public function main() returns error? {
    Book addBookRequest = {isbn: "ballerina", title: "ballerina", author: "ballerina", location: "ballerina", status: true};
    string addBookResponse = check ep->addBook(addBookRequest);
    io:println(addBookResponse);
    Book updateBookRequest = {isbn: "ballerina", title: "ballerina", author: "ballerina", location: "ballerina", status: true};
    string updateBookResponse = check ep->updateBook(updateBookRequest);
    io:println(updateBookResponse);
    string removeBookRequest = "ballerina";
    Book removeBookResponse = check ep->removeBook(removeBookRequest);
    io:println(removeBookResponse);
    locBook locateBookRequest = {book_isbn: "ballerina"};
    Book locateBookResponse = check ep->locateBook(locateBookRequest);
    io:println(locateBookResponse);
    Request borrowBookRequest = {user_id: "ballerina", book_isbn: "ballerina"};
    string borrowBookResponse = check ep->borrowBook(borrowBookRequest);
    io:println(borrowBookResponse);
    stream<
Book, error?> listAvailableBooksResponse = check ep->listAvailableBooks();
    check listAvailableBooksResponse.forEach(function(Book value) {
        io:println(value);
    });
    User createUsersRequest = {id: "ballerina", name: "ballerina"};
    CreateUsersStreamingClient createUsersStreamingClient = check ep->createUsers();
    check createUsersStreamingClient->sendUser(createUsersRequest);
    check createUsersStreamingClient->complete();
    string? createUsersResponse = check createUsersStreamingClient->receiveString();
    io:println(createUsersResponse);
}