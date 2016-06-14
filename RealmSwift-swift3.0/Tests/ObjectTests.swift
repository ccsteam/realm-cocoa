////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import XCTest
import RealmSwift
import Foundation

class ObjectTests: TestCase {

    // init() Tests are in ObjectCreationTests.swift

    // init(value:) tests are in ObjectCreationTests.swift

    func testRealm() {
        let standalone = SwiftStringObject()
        XCTAssertNil(standalone.realm)

        let realm = try! Realm()
        var persisted: SwiftStringObject!
        try! realm.write {
            persisted = realm.createObject(ofType: SwiftStringObject.self, populatedWith: [:])
            XCTAssertNotNil(persisted.realm)
            XCTAssertEqual(realm, persisted.realm!)
        }
        XCTAssertNotNil(persisted.realm)
        XCTAssertEqual(realm, persisted.realm!)

        dispatchSyncNewThread {
            autoreleasepool {
                XCTAssertNotEqual(try! Realm(), persisted.realm!)
            }
        }
    }

    func testObjectSchema() {
        let object = SwiftObject()
        let schema = object.objectSchema
        XCTAssert(schema as AnyObject is ObjectSchema)
        XCTAssert(schema.properties as AnyObject is [Property])
        XCTAssertEqual(schema.className, "SwiftObject")
        XCTAssertEqual(schema.properties.map { $0.name },
            ["boolCol", "intCol", "floatCol", "doubleCol", "stringCol", "binaryCol", "dateCol", "objectCol", "arrayCol"]
        )
    }

    func testObjectSchemaForObjectWithConvenienceInitializer() {
        let object = SwiftConvenienceInitializerObject(stringCol: "abc")
        let schema = object.objectSchema
        XCTAssert(schema as AnyObject is ObjectSchema)
        XCTAssert(schema.properties as AnyObject is [Property])
        XCTAssertEqual(schema.className, "SwiftConvenienceInitializerObject")
        XCTAssertEqual(schema.properties.map { $0.name }, ["stringCol"])
    }

    func testInvalidated() {
        let object = SwiftObject()
        XCTAssertFalse(object.isInvalidated)

        let realm = try! Realm()
        try! realm.write {
            realm.add(object)
            XCTAssertFalse(object.isInvalidated)
        }

        try! realm.write {
            realm.deleteAllObjects()
            XCTAssertTrue(object.isInvalidated)
        }
        XCTAssertTrue(object.isInvalidated)
    }

    func testDescription() {
        let object = SwiftObject()
        // swiftlint:disable line_length
        XCTAssertEqual(object.description, "SwiftObject {\n\tboolCol = 0;\n\tintCol = 123;\n\tfloatCol = 1.23;\n\tdoubleCol = 12.3;\n\tstringCol = a;\n\tbinaryCol = <61 — 1 total bytes>;\n\tdateCol = 1970-01-01 00:00:01 +0000;\n\tobjectCol = SwiftBoolObject {\n\t\tboolCol = 0;\n\t};\n\tarrayCol = List<SwiftBoolObject> (\n\t\n\t);\n}")

        let recursiveObject = SwiftRecursiveObject()
        recursiveObject.objects.append(recursiveObject)
        XCTAssertEqual(recursiveObject.description, "SwiftRecursiveObject {\n\tobjects = List<SwiftRecursiveObject> (\n\t\t[0] SwiftRecursiveObject {\n\t\t\tobjects = List<SwiftRecursiveObject> (\n\t\t\t\t[0] SwiftRecursiveObject {\n\t\t\t\t\tobjects = <Maximum depth exceeded>;\n\t\t\t\t}\n\t\t\t);\n\t\t}\n\t);\n}")
        // swiftlint:enable line_length
    }

    func testPrimaryKey() {
        XCTAssertNil(Object.primaryKey(), "primary key should default to nil")
        XCTAssertNil(SwiftStringObject.primaryKey())
        XCTAssertNil(SwiftStringObject().objectSchema.primaryKeyProperty)
        XCTAssertEqual(SwiftPrimaryStringObject.primaryKey()!, "stringCol")
        XCTAssertEqual(SwiftPrimaryStringObject().objectSchema.primaryKeyProperty!.name, "stringCol")
    }

    func testIgnoredProperties() {
        XCTAssertEqual(Object.ignoredProperties(), [], "ignored properties should default to []")
        XCTAssertEqual(SwiftIgnoredPropertiesObject.ignoredProperties().count, 2)
        XCTAssertNil(SwiftIgnoredPropertiesObject().objectSchema["runtimeProperty"])
    }

    func testIndexedProperties() {
        XCTAssertEqual(Object.indexedProperties(), [], "indexed properties should default to []")
        XCTAssertEqual(SwiftIndexedPropertiesObject.indexedProperties().count, 8)

        let objectSchema = SwiftIndexedPropertiesObject().objectSchema
        XCTAssertTrue(objectSchema["stringCol"]!.isIndexed)
        XCTAssertTrue(objectSchema["intCol"]!.isIndexed)
        XCTAssertTrue(objectSchema["int8Col"]!.isIndexed)
        XCTAssertTrue(objectSchema["int16Col"]!.isIndexed)
        XCTAssertTrue(objectSchema["int32Col"]!.isIndexed)
        XCTAssertTrue(objectSchema["int64Col"]!.isIndexed)
        XCTAssertTrue(objectSchema["boolCol"]!.isIndexed)
        XCTAssertTrue(objectSchema["dateCol"]!.isIndexed)

        XCTAssertFalse(objectSchema["floatCol"]!.isIndexed)
        XCTAssertFalse(objectSchema["doubleCol"]!.isIndexed)
        XCTAssertFalse(objectSchema["dataCol"]!.isIndexed)
    }

    func testIndexedOptionalProperties() {
        XCTAssertEqual(Object.indexedProperties(), [], "indexed properties should default to []")
        XCTAssertEqual(SwiftIndexedOptionalPropertiesObject.indexedProperties().count, 8)
        XCTAssertTrue(SwiftIndexedOptionalPropertiesObject().objectSchema["optionalStringCol"]!.isIndexed)
        XCTAssertTrue(SwiftIndexedOptionalPropertiesObject().objectSchema["optionalDateCol"]!.isIndexed)
        XCTAssertTrue(SwiftIndexedOptionalPropertiesObject().objectSchema["optionalBoolCol"]!.isIndexed)
        XCTAssertTrue(SwiftIndexedOptionalPropertiesObject().objectSchema["optionalIntCol"]!.isIndexed)
        XCTAssertTrue(SwiftIndexedOptionalPropertiesObject().objectSchema["optionalInt8Col"]!.isIndexed)
        XCTAssertTrue(SwiftIndexedOptionalPropertiesObject().objectSchema["optionalInt16Col"]!.isIndexed)
        XCTAssertTrue(SwiftIndexedOptionalPropertiesObject().objectSchema["optionalInt32Col"]!.isIndexed)
        XCTAssertTrue(SwiftIndexedOptionalPropertiesObject().objectSchema["optionalInt64Col"]!.isIndexed)

        XCTAssertFalse(SwiftIndexedOptionalPropertiesObject().objectSchema["optionalDataCol"]!.isIndexed)
        XCTAssertFalse(SwiftIndexedOptionalPropertiesObject().objectSchema["optionalFloatCol"]!.isIndexed)
        XCTAssertFalse(SwiftIndexedOptionalPropertiesObject().objectSchema["optionalDoubleCol"]!.isIndexed)
    }

    func testValueForKey() {
        let test: (SwiftObject) -> () = { object in
            XCTAssertEqual(object.value(forKey: "boolCol") as! Bool!, false)
            XCTAssertEqual(object.value(forKey: "intCol") as! Int!, 123)
            XCTAssertEqual(object.value(forKey: "floatCol") as! Float!, 1.23 as Float)
            XCTAssertEqual(object.value(forKey: "doubleCol") as! Double!, 12.3)
            XCTAssertEqual(object.value(forKey: "stringCol") as! String!, "a")

            let expected = (object.value(forKey: "binaryCol") as! NSData) as Data
            let actual = "a".data(using: String.Encoding.utf8)!
            XCTAssertTrue(expected == actual)

            XCTAssertEqual(object.value(forKey: "dateCol") as! NSDate!, NSDate(timeIntervalSince1970: 1))
            XCTAssertEqual((object.value(forKey: "objectCol")! as! SwiftBoolObject).boolCol, false)
            XCTAssert(object.value(forKey: "arrayCol")! is List<SwiftBoolObject>)
        }

        test(SwiftObject())
        try! Realm().write {
            let persistedObject = try! Realm().createObject(ofType: SwiftObject.self, populatedWith: [:])
            test(persistedObject)
        }
    }

    func setAndTestAllTypes(_ setter: (SwiftObject, AnyObject?, String) -> (),
                            getter: (SwiftObject, String) -> (AnyObject?), object: SwiftObject) {
        setter(object, true, "boolCol")
        XCTAssertEqual(getter(object, "boolCol") as! Bool!, true)

        setter(object, 321, "intCol")
        XCTAssertEqual(getter(object, "intCol") as! Int!, 321)

        setter(object, NSNumber(value: 32.1 as Float), "floatCol")
        XCTAssertEqual(getter(object, "floatCol") as! Float!, 32.1 as Float)

        setter(object, 3.21, "doubleCol")
        XCTAssertEqual(getter(object, "doubleCol") as! Double!, 3.21)

        setter(object, "z", "stringCol")
        XCTAssertEqual(getter(object, "stringCol") as! String!, "z")

        setter(object, "z".data(using: String.Encoding.utf8), "binaryCol")
        let gotData = (getter(object, "binaryCol") as! NSData) as Data
        XCTAssertTrue(gotData == "z".data(using: String.Encoding.utf8)!)

        setter(object, NSDate(timeIntervalSince1970: 333), "dateCol")
        XCTAssertEqual(getter(object, "dateCol") as! NSDate!, NSDate(timeIntervalSince1970: 333))

        let boolObject = SwiftBoolObject(value: [true])
        setter(object, boolObject, "objectCol")
        XCTAssertEqual(getter(object, "objectCol") as? SwiftBoolObject, boolObject)
        XCTAssertEqual((getter(object, "objectCol") as! SwiftBoolObject).boolCol, true)

        let list = List<SwiftBoolObject>()
        list.append(boolObject)
        setter(object, list, "arrayCol")
        XCTAssertEqual((getter(object, "arrayCol") as! List<SwiftBoolObject>).count, 1)
        XCTAssertEqual((getter(object, "arrayCol") as! List<SwiftBoolObject>).first!, boolObject)

        list.removeAllObjects()
        setter(object, list, "arrayCol")
        XCTAssertEqual((getter(object, "arrayCol") as! List<SwiftBoolObject>).count, 0)

        setter(object, [boolObject], "arrayCol")
        XCTAssertEqual((getter(object, "arrayCol") as! List<SwiftBoolObject>).count, 1)
        XCTAssertEqual((getter(object, "arrayCol") as! List<SwiftBoolObject>).first!, boolObject)
    }

    func dynamicSetAndTestAllTypes(_ setter: (DynamicObject, AnyObject?, String) -> (),
                                   getter: (DynamicObject, String) -> (AnyObject?), object: DynamicObject,
                                   boolObject: DynamicObject) {
        setter(object, true, "boolCol")
        XCTAssertEqual((getter(object, "boolCol") as! Bool), true)

        setter(object, 321, "intCol")
        XCTAssertEqual((getter(object, "intCol") as! Int), 321)

        setter(object, NSNumber(value: 32.1 as Float), "floatCol")
        XCTAssertEqual((getter(object, "floatCol") as! Float), 32.1 as Float)

        setter(object, 3.21, "doubleCol")
        XCTAssertEqual((getter(object, "doubleCol") as! Double), 3.21)

        setter(object, "z", "stringCol")
        XCTAssertEqual((getter(object, "stringCol") as! String), "z")

        setter(object, "z".data(using: String.Encoding.utf8), "binaryCol")
        let gotData = (getter(object, "binaryCol") as! NSData) as Data
        XCTAssertTrue(gotData == "z".data(using: String.Encoding.utf8)!)

        setter(object, NSDate(timeIntervalSince1970: 333), "dateCol")
        XCTAssertEqual((getter(object, "dateCol") as! NSDate), NSDate(timeIntervalSince1970: 333))

        setter(object, boolObject, "objectCol")
        XCTAssertEqual((getter(object, "objectCol") as! DynamicObject), boolObject)
        XCTAssertEqual(((getter(object, "objectCol") as! DynamicObject)["boolCol"] as! NSNumber), true as NSNumber)

        setter(object, [boolObject], "arrayCol")
        XCTAssertEqual((getter(object, "arrayCol") as! List<DynamicObject>).count, 1)
        XCTAssertEqual((getter(object, "arrayCol") as! List<DynamicObject>).first!, boolObject)

        let list = getter(object, "arrayCol") as! List<DynamicObject>
        list.removeAllObjects()
        setter(object, list, "arrayCol")
        XCTAssertEqual((getter(object, "arrayCol") as! List<DynamicObject>).count, 0)

        setter(object, [boolObject], "arrayCol")
        XCTAssertEqual((getter(object, "arrayCol") as! List<DynamicObject>).count, 1)
        XCTAssertEqual((getter(object, "arrayCol") as! List<DynamicObject>).first!, boolObject)
    }

    // Yields a read-write migration `SwiftObject` to the given block
    private func withMigrationObject(block: ((MigrationObject, Migration) -> ())) {
        autoreleasepool {
            let realm = self.realmWithTestPath()
            try! realm.write {
                _ = realm.createObject(ofType: SwiftObject.self)
            }
        }
        autoreleasepool {
            var enumerated = false
            let configuration = Realm.Configuration(schemaVersion: 1, migrationBlock: { migration, _ in
                migration.enumerateObjects(ofType: SwiftObject.className()) { oldObject, newObject in
                    if let newObject = newObject {
                        block(newObject, migration)
                        enumerated = true
                    }
                }
            })
            self.realmWithTestPath(configuration: configuration)
            XCTAssert(enumerated)
        }
    }

    func testSetValueForKey() {
        let setter: (Object, AnyObject?, String) -> () = { object, value, key in
            object.setValue(value, forKey: key)
            return
        }
        let getter: (Object, String) -> (AnyObject?) = { object, key in
            object.value(forKey: key)
        }

        withMigrationObject { migrationObject, migration in
            let boolObject = migration.createObject(ofType: "SwiftBoolObject", populatedWith: [true])
            self.dynamicSetAndTestAllTypes(setter, getter: getter, object: migrationObject, boolObject: boolObject)
        }

        setAndTestAllTypes(setter, getter: getter, object: SwiftObject())
        try! Realm().write {
            let persistedObject = try! Realm().createObject(ofType: SwiftObject.self, populatedWith: [:])
            self.setAndTestAllTypes(setter, getter: getter, object: persistedObject)
        }
    }

    func testSubscript() {
        let setter: (Object, AnyObject?, String) -> () = { object, value, key in
            object[key] = value
            return
        }
        let getter: (Object, String) -> (AnyObject?) = { object, key in
            object[key]
        }

        withMigrationObject { migrationObject, migration in
            let boolObject = migration.createObject(ofType: "SwiftBoolObject", populatedWith: [true])
            self.dynamicSetAndTestAllTypes(setter, getter: getter, object: migrationObject, boolObject: boolObject)
        }

        setAndTestAllTypes(setter, getter: getter, object: SwiftObject())
        try! Realm().write {
            let persistedObject = try! Realm().createObject(ofType: SwiftObject.self, populatedWith: [:])
            self.setAndTestAllTypes(setter, getter: getter, object: persistedObject)
        }
    }

    func testDynamicList() {
        let realm = try! Realm()
        let arrayObject = SwiftArrayPropertyObject()
        let str1 = SwiftStringObject()
        let str2 = SwiftStringObject()
        arrayObject.array.append(objectsIn: [str1, str2])
        try! realm.write {
            realm.add(arrayObject)
        }
        let dynamicArray = arrayObject.dynamicList("array")
        XCTAssertEqual(dynamicArray.count, 2)
        XCTAssertEqual(dynamicArray[0], str1)
        XCTAssertEqual(dynamicArray[1], str2)
        XCTAssertEqual(arrayObject.dynamicList("intArray").count, 0)
        assertThrows(arrayObject.dynamicList("noSuchList"))
    }
}
