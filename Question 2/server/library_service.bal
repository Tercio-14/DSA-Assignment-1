import ballerina/grpc;

listener grpc:Listener ep = new (9090);

@grpc:Descriptor {value: LIBRARY_DESC}
service "Library" on ep {

    remote function addBook(Book value) returns string|error {
        
    }
    remote function updateBook(Book value) returns string|error {
    }
    remote function removeBook(string value) returns Book|error {
    }
    remote function locateBook(locBook value) returns Book|error {
    }
    remote function borrowBook(Request value) returns string|error {
    }
    remote function createUsers(stream<User, grpc:Error?> clientStream) returns string|error {
    }
    remote function listAvailableBooks() returns stream<Book, error?>|error {
    }
}

