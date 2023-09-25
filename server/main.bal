import ballerina/http;

//Records
type Lecturer record {
    readonly string LecturerNumber;
    string officeNumber;
    string LecturerName;
    string title;
};

type Office record {
    readonly string officeNumber;
    string location;
    int capcity;
    string lecturer;
};

type Courses record {
    readonly string courseCode;
    string courseName;
    int NQFLevel;
};

table<Lecturer> key(LecturerNumber) lecturerTable = table [];
table<Office> key(officeNumber) officeTable = table [];
table<Courses> key(courseCode) courseTable = table [];

service / on new http:Listener(2023) {
    //Retrieve the details of a specific lecturer by their Lecturer number
    resource function get lecturers/[string LecturerNumber]() returns Lecturer[] {
        if (LecturerNumber !== "") {
            table<Lecturer> lects = from var lecturer in lecturerTable
                where lecturer.LecturerNumber === LecturerNumber
                select lecturer;
            table<Lecturer> lecturers = lects;
            return lecturers.toArray();
        }
        return [];
    }

    // Retrieve all the lecturers that sit in the same office
    resource function get lecturer/[string officeNumber]() returns Lecturer[] {
        if (officeNumber !== "") {
            table<Lecturer> lects = from var lecturer in lecturerTable
                where lecturer.officeNumber === officeNumber
                select lecturer;
            table<Lecturer> results = lects;
            return results.toArray();
        }
        return [];
    }

    //Retrieve a list of all lecturers withtin the faculty
    resource function get lecturer() returns Lecturer[] {
        table<Lecturer> lects = from var lecturer in lecturerTable
            select lecturer;
        table<Lecturer> results = lects;
        return results.toArray();
    }

    //delete Lecturer by LecturerNumber
    resource function delete lecturer/[string LecturerNumber]() returns string {
        Lecturer|error delete = lecturerTable.remove(LecturerNumber);

        if (delete is error) {
            return "Error " + delete.message();
        } else {
            return delete.LecturerName + "delete successfuly";
        }
    }

    //Retrieve all lecturers that teach a specific course
    resource function get LecturerAndCourse/[string courseCode]() returns table<record {|string lecturerName; string courseCode;|}> {
        var lecturer = from var lecturers in lecturerTable
            join var courses in courseTable
            on lecturers.LecturerNumber equals courses.courseCode
            select {
                lecturerName: lecturers.LecturerName,
                courseCode: courses.courseCode
            };

        return lecturer;
    }

    //add a  new lecturer
    resource function post lecturer(Lecturer lecture) returns string {
        error? newUser = lecturerTable.add(lecture);

        if (newUser is error) {
            return "Error " + newUser.message();
        } else {
            return "lecturer saved successfuly";
        }
    };

    //add data test for all tables
    resource function post office(Office office) returns string {
        error? newOffice = officeTable.add(office);
        if (newOffice is error) {
            return "Error " + newOffice.message();
        } else {
            return "office saved successfuly";
        }
    };

    resource function post courses(Courses courses) returns string {
        error? newCourse = courseTable.add(courses);
        if (newCourse is error) {
            return "Error " + newCourse.message();
        } else {
            return "course saved successfuly";
        }
    };
}
