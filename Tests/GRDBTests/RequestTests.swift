import XCTest
#if USING_SQLCIPHER
    import GRDBCipher
#elseif USING_CUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

class RequestTests: GRDBTestCase {
    
    func testRequestFetch() throws {
        struct CustomRequest : Request {
            func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
                return try (db.makeSelectStatement("SELECT * FROM table1"), nil)
            }
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "table1") { t in
                t.column("id", .integer).primaryKey()
            }
            try db.execute("INSERT INTO table1 DEFAULT VALUES")
            try db.execute("INSERT INTO table1 DEFAULT VALUES")
            
            let request: Request = CustomRequest()  // Lose type
            let rows = try Row.fetchAll(db, request)
            XCTAssertEqual(lastSQLQuery, "SELECT * FROM table1")
            XCTAssertEqual(rows.count, 2)
            XCTAssertEqual(rows[0], ["id": 1])
            XCTAssertEqual(rows[1], ["id": 2])
        }
    }
    
    func testRequestFetchCount() throws {
        struct CustomRequest : Request {
            func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
                return try (db.makeSelectStatement("SELECT * FROM table1"), nil)
            }
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "table1") { t in
                t.column("id", .integer).primaryKey()
            }
            try db.execute("INSERT INTO table1 DEFAULT VALUES")
            try db.execute("INSERT INTO table1 DEFAULT VALUES")
            
            let request: Request = CustomRequest()  // Lose type
            let count = try request.fetchCount(db)
            XCTAssertEqual(lastSQLQuery, "SELECT COUNT(*) FROM (SELECT * FROM table1)")
            XCTAssertEqual(count, 2)
        }
    }
    
    func testRequestCustomizedFetchCount() throws {
        struct CustomRequest : Request {
            func prepare(_ db: Database) throws -> (SelectStatement, RowAdapter?) {
                return try (db.makeSelectStatement("INVALID"), nil)
            }
            
            func fetchCount(_ db: Database) throws -> Int {
                return 2
            }
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "table1") { t in
                t.column("id", .integer).primaryKey()
            }
            try db.execute("INSERT INTO table1 DEFAULT VALUES")
            try db.execute("INSERT INTO table1 DEFAULT VALUES")
            
            let request: Request = CustomRequest()  // Lose type
            let count = try request.fetchCount(db)
            XCTAssertEqual(lastSQLQuery, "INSERT INTO table1 DEFAULT VALUES")
            XCTAssertEqual(count, 2)
        }
    }
}
