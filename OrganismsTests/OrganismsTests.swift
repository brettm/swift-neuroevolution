//
//  OrganismsTests.swift
//  OrganismsTests
//
//  Created by Brett Meader on 04/03/2024.
//

import XCTest

@testable import Organisms

final class OrganismsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testModel() {
        var model = OrganismModel()
        XCTAssert(model.createNetwork() != false)
        let pred = model.predict([0.5, 0.5, 0.1, -0.5, -0.5, 1.0, -1.0, 0.0, 1.0])
        XCTAssert(pred.count == MLPNodeShape.outputNodesCount)
    }
    
    func testVector2d() {
        var vectorA = Vector2d()
        var vectorB = Vector2d(x: 1, y: 1)
        var vectores = [vectorA, vectorB].filterByDistance(0)
        XCTAssert(vectores.count == 1)
        XCTAssert(vectores.first == vectorA)
        
        vectores = [vectorA, vectorB].filterByDistance(0.1)
        XCTAssert(vectores.count == 1)
        XCTAssert(vectores.first == vectorA)
        
        vectores = [vectorA, vectorB].filterByDistance(0.1, relativeTo: vectorB)
        XCTAssert(vectores.count == 1)
        XCTAssert(vectores.first == vectorB)
        
        vectores = [vectorA, vectorB].filterByDistance(1.5, relativeTo: vectorB)
        XCTAssert(vectores.count == 2)
        
        vectorA = Vector2d(x: -1.2, y: -1.2)
        vectores = [vectorA, vectorB].filterByDistance(0)
        XCTAssert(vectores.count == 0)
        
        vectores = [vectorA, vectorB].filterByDistance(0.1)
        XCTAssert(vectores.count == 0)
        
        vectores = [vectorA, vectorB].filterByDistance(1.5)
        XCTAssert(vectores.count == 1)
        XCTAssert(vectores.first == vectorB)
        
        vectores = [vectorA, vectorB].filterByDistance(1.8)
        XCTAssert(vectores.count == 2)
        
        vectores = [vectorA, vectorB].filterByDistance(0.1, relativeTo: vectorB)
        XCTAssert(vectores.count == 1)
        XCTAssert(vectores.first == vectorB)
        
        vectores = [vectorA, vectorB].filterByDistance(0.1, relativeTo: vectorA)
        XCTAssert(vectores.count == 1)
        XCTAssert(vectores.first == vectorA)
        
        vectores = [vectorA, vectorB].filterByDistance(2, relativeTo: vectorA)
        XCTAssert(vectores.count == 1)
        XCTAssert(vectores.first == vectorA)
        
        vectores = [vectorA, vectorB].filterByDistance(5, relativeTo: vectorA)
        XCTAssert(vectores.count == 2)
    }

}
