//
//  ViewController.swift
//  SwiftRecordExample
//
//  Created by Zaid on 5/8/15.
//  Copyright (c) 2015 ark. All rights reserved.
//

import Foundation
import UIKit
import SwiftRecord

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let test: TestEntity = TestEntity.create(properties: ["string":"testString", "date":NSDate(), "integer":NSNumber(integer: 5), "float":NSNumber(float: 5)]) as! TestEntity
        print("test.string = " + test.string)
        print("test.date = \(test.date)")
        print("test.integer = \(test.integer)")
        print("test.float = \(test.float)")
        test.save()
        let testrel = TestEntityRelationship.create(properties: ["string":"someName"]) as! TestEntityRelationship
        testrel.save()
        
        SwiftRecord.generateRelationships = true
        //SwiftRecord.setUpEntities(["TestEntity":TestEntity.self,"TestEntityRelationship":TestEntityRelationship.self])
        
        let test2 = TestEntity.create(properties: ["string":"testString2", "relationship":["string":"anotherName"],"relationships":[["string":"array1"],["string":"array2"],["string":"array3"]]]) as! TestEntity
        print(test2.string)
        print(test2.relationship.string)
        for er in test2.relationships {
            let e = er as! TestEntityRelationship
            print(e.string)
        }
        test2.save()
        test2.delete()
        let dq = "date < %@"
        print("Date Query Count: \(TestEntity.query(dq, args: NSDate()).count)")
        let q = ["string":"testString"]
        print("Query count: \(TestEntity.query(q).count)")
        TestEntity.all(sort: "date ASC, integer DESC")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

