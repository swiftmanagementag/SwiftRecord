//
//  SwiftRecord.swift
//
//  ark - http://www.arkverse.com
//  Created by Zaid on 5/7/15.
//
//
// swiftlint:disable strict_fileprivate function_default_parameter_at_end force_unwrapping force_cast force_try

import CoreData
import Foundation
#if os(iOS)
    import UIKit
#endif

open class SwiftRecord {
    public static var generateRelationships = false

    public static func setUpEntities(_ entities: [String: NSManagedObject.Type]) {
        nameToEntities = entities
    }

    fileprivate static var nameToEntities = [String: NSManagedObject.Type]()

    public let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""

    open var databaseName: String {
        get {
            if let db = _databaseName {
                return db
            } else {
                return appName + ".sqlite"
            }
        }
        set {
            _databaseName = newValue
            if _managedObjectContext != nil {
                _managedObjectContext = nil
            }
            if _persistentStoreCoordinator != nil {
                _persistentStoreCoordinator = nil
            }
        }
    }

    private var _databaseName: String?

    open var modelName: String {
        get {
            if let model = _modelName {
                return model
            } else {
                return appName
            }
        }
        set {
            _modelName = newValue
            if _managedObjectContext != nil {
                _managedObjectContext = nil
            }
            if _persistentStoreCoordinator != nil {
                _persistentStoreCoordinator = nil
            }
        }
    }

    private var _modelName: String?

    open var managedObjectContext: NSManagedObjectContext {
        get {
            if let context = _managedObjectContext {
                return context
            } else {
                let c = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
                c.persistentStoreCoordinator = persistentStoreCoordinator
                _managedObjectContext = c
                return c
            }
        }
        set {
            _managedObjectContext = newValue
        }
    }

    private var _managedObjectContext: NSManagedObjectContext?

    open var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        if let store = _persistentStoreCoordinator {
            return store
        } else {
            let p = self.persistentStoreCoordinator(NSSQLiteStoreType, storeURL: sqliteStoreURL)
            _persistentStoreCoordinator = p
            return p
        }
    }

    private var _persistentStoreCoordinator: NSPersistentStoreCoordinator?

    open var managedObjectModel: NSManagedObjectModel {
        get {
            if let m = _managedObjectModel {
                return m
            } else {
                let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd")
                _managedObjectModel = NSManagedObjectModel(contentsOf: modelURL!)
                return _managedObjectModel!
            }
        }
        set {
            _managedObjectModel = newValue
        }
    }

    private var _managedObjectModel: NSManagedObjectModel?

    open func useInMemoryStore() {
        _persistentStoreCoordinator = persistentStoreCoordinator(NSInMemoryStoreType, storeURL: nil)
    }

    open func saveContext() -> Bool {
        print("Class saveContext: \(managedObjectContext.debugDescription)")

        if !managedObjectContext.hasChanges {
            return false
        }

        do {
            try managedObjectContext.save()
        } catch let error as NSError {
            print("Unresolved error in saving context! " + error.debugDescription)
            return false
        }

        return true
    }

    open func applicationDocumentsDirectory() -> URL {
        FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last!
    }

    open func applicationSupportDirectory() -> URL {
        (FileManager.default.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last!).appendingPathComponent(appName)
    }

    open var sqliteStoreURL: URL {
        #if os(iOS)
            let dir = applicationDocumentsDirectory()
        #else
            let dir = applicationSupportDirectory()
            createApplicationSupportDirIfNeeded(dir)
        #endif
        return dir.appendingPathComponent(databaseName)
    }

    private func persistentStoreCoordinator(_ storeType: String, storeURL: URL?) -> NSPersistentStoreCoordinator {
        let c = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        do {
            try c.addPersistentStore(ofType: storeType, configurationName: nil, at: storeURL, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
        } catch let error as NSError {
            print("ERROR WHILE CREATING PERSISTENT STORE COORDINATOR! " + error.debugDescription)
        }
        return c
    }

    private func createApplicationSupportDirIfNeeded(_ dir: URL) {
        if FileManager.default.fileExists(atPath: dir.absoluteString) {
            return
        }
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("ERROR WHILE CREATING APPLICATION SUPPORT DIRECTORY! " + error.debugDescription)
        }
    }

    private init() {
        #if os(iOS)
            NotificationCenter.default.addObserver(self, selector: #selector(SwiftRecord.applicationWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
        #endif
    }

    @objc open func applicationWillTerminate() {
        #if os(iOS)
            _ = saveContext()
        #endif
    }

    // singleton
    public static let sharedRecord = SwiftRecord()
}

public extension NSManagedObjectContext {
    static var defaultContext: NSManagedObjectContext {
        SwiftRecord.sharedRecord.managedObjectContext
    }
}

extension NSManagedObject {
    // Querying
    @nonobjc public static func all(context: NSManagedObjectContext = NSManagedObjectContext.defaultContext) -> [NSManagedObject] {
        fetch(predicate: nil, context: context, sortQuery: nil, limit: nil)
    }

    @nonobjc public static func all(context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: String?) -> [NSManagedObject] {
        fetch(predicate: nil, context: context, sortQuery: sort, limit: nil)
    }

    @nonobjc public static func all(context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: [[String: Any]]?) -> [NSManagedObject] {
        fetch(predicate: nil, context: context, sortConditions: sort, limit: nil)
    }

    @nonobjc public static func findOrCreate(_ properties: [String: Any]) -> NSManagedObject {
        findOrCreate(properties, context: NSManagedObjectContext.defaultContext)
    }

    @nonobjc public static func findOrCreate(_ properties: [String: Any], context: NSManagedObjectContext) -> NSManagedObject {
        let transformed = transformProperties(properties, context: context)
        let existing: NSManagedObject? = query(transformed, context: context).first
        return existing ?? create(transformed, context: context)
    }

    @nonobjc public static func find(_ condition: String, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, argsArray: [Any]? = nil) -> NSManagedObject? {
        query(condition, context: context, limit: 1, argsArray: argsArray).first
    }

    @nonobjc public static func find(_ condition: String, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, args: Any...) -> NSManagedObject? {
        query(condition, context: context, limit: 1, argsArray: args).first
    }

    @nonobjc public static func find(_ condition: String, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: String?, argsArray: [Any]? = nil) -> NSManagedObject? {
        query(condition, context: context, sort: sort, limit: 1, argsArray: argsArray).first
    }

    @nonobjc public static func find(_ condition: String, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: String?, args: Any...) -> NSManagedObject? {
        query(condition, context: context, sort: sort, limit: 1, argsArray: args).first
    }

    @nonobjc public static func find(_ condition: String, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: [[String: Any]]?, argsArray: [Any]? = nil) -> NSManagedObject? {
        query(condition, context: context, sort: sort, limit: 1, argsArray: argsArray).first
    }

    @nonobjc public static func find(_ condition: String, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: [[String: Any]]?, args: Any...) -> NSManagedObject? {
        query(condition, context: context, sort: sort, limit: 1, argsArray: args).first
    }

    @nonobjc public static func find(_ condition: [String: Any], context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: String?) -> NSManagedObject? {
        query(condition, context: context, sort: sort, limit: 1).first
    }

    @nonobjc public static func find(_ condition: [String: Any], context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: [[String: Any]]?) -> NSManagedObject? {
        query(condition, context: context, sort: sort, limit: 1).first
    }

    @nonobjc public static func find(_ condition: NSPredicate, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: String?) -> NSManagedObject? {
        query(condition, context: context, sort: sort, limit: 1).first
    }

    @nonobjc public static func find(_ condition: NSPredicate, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: [[String: Any]]?) -> NSManagedObject? {
        query(condition, context: context, sort: sort, limit: 1).first
    }

    @nonobjc public static func query(_ condition: String, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, limit: Int? = nil, argsArray: [Any]? = nil) -> [NSManagedObject] {
        fetch(query: condition, context: context, sortDescriptors: nil, limit: limit, args: argsArray)
    }

    @nonobjc public static func query(_ condition: String, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, limit: Int? = nil, args: Any...) -> [NSManagedObject] {
        fetch(query: condition, context: context, sortDescriptors: nil, limit: limit, args: args)
    }

    @nonobjc public static func query(_ condition: String, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: String?, limit: Int? = nil, argsArray: [Any]? = nil) -> [NSManagedObject] {
        fetch(query: condition, context: context, sortQuery: sort, limit: limit, args: argsArray)
    }

    @nonobjc public static func query(_ condition: String, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: String?, limit: Int? = nil, args: Any...) -> [NSManagedObject] {
        fetch(query: condition, context: context, sortQuery: sort, limit: limit, args: args)
    }

    @nonobjc public static func query(_ condition: String, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: [[String: Any]]?, limit: Int? = nil, argsArray: [Any]? = nil) -> [NSManagedObject] {
        fetch(query: condition, context: context, sortConditions: sort, limit: limit, args: argsArray)
    }

    @nonobjc public static func query(_ condition: String, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: [[String: Any]]?, limit: Int? = nil, args: Any...) -> [NSManagedObject] {
        fetch(query: condition, context: context, sortConditions: sort, limit: limit, args: args)
    }

    @nonobjc public static func query(_ condition: String, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: [String: Any]?, limit: Int? = nil, argsArray: [Any]? = nil) -> [NSManagedObject] {
        fetch(query: condition, context: context, sortCondition: sort, limit: limit, args: argsArray)
    }

    @nonobjc public static func query(_ condition: String, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: [String: Any]?, limit: Int? = nil, args: Any...) -> [NSManagedObject] {
        fetch(query: condition, context: context, sortCondition: sort, limit: limit, args: args)
    }

    @nonobjc public static func query(_ condition: [String: Any], context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, limit: Int? = nil) -> [NSManagedObject] {
        fetch(properties: condition, context: context, sortDescriptors: nil, limit: limit)
    }

    @nonobjc public static func query(_ condition: [String: Any], context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: String?, limit: Int? = nil) -> [NSManagedObject] {
        fetch(properties: condition, context: context, sortQuery: sort, limit: limit)
    }

    @nonobjc public static func query(_ condition: [String: Any], context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: [[String: Any]]?, limit: Int? = nil) -> [NSManagedObject] {
        fetch(properties: condition, context: context, sortConditions: sort, limit: limit)
    }

    @nonobjc public static func query(_ condition: [String: Any], context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: [String: Any]?, limit: Int? = nil) -> [NSManagedObject] {
        fetch(properties: condition, context: context, sortCondition: sort, limit: limit)
    }

    @nonobjc public static func query(_ condition: NSPredicate, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, limit: Int? = nil) -> [NSManagedObject] {
        fetch(predicate: condition, context: context, sortDescriptors: nil, limit: limit)
    }

    @nonobjc public static func query(_ condition: NSPredicate, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: [[String: Any]]?, limit: Int? = nil) -> [NSManagedObject] {
        fetch(predicate: condition, context: context, sortConditions: sort, limit: limit)
    }

    @nonobjc public static func query(_ condition: NSPredicate, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: [String: Any]?, limit: Int? = nil) -> [NSManagedObject] {
        fetch(predicate: condition, context: context, sortCondition: sort, limit: limit)
    }

    @nonobjc public static func query(_ condition: NSPredicate, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, sort: String?, limit: Int? = nil) -> [NSManagedObject] {
        fetch(predicate: condition, context: context, sortQuery: sort, limit: limit)
    }

    // Aggregation
    @nonobjc public static func count(_ context: NSManagedObjectContext = NSManagedObjectContext.defaultContext) -> Int {
        countForFetch(nil, context: context)
    }

    @nonobjc public static func count(query: [String: Any], context: NSManagedObjectContext = NSManagedObjectContext.defaultContext) -> Int {
        let predicate = self.predicate(query)
        return countForFetch(predicate, context: context)
    }

    @nonobjc public static func count(query: String, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext, args: Any...) -> Int {
        let predicate = self.predicate(query, args: args)
        return countForFetch(predicate, context: context)
    }

    @nonobjc public static func count(query: NSPredicate, context: NSManagedObjectContext = NSManagedObjectContext.defaultContext) -> Int {
        countForFetch(query, context: context)
    }

    // Creation / Deletion
    @nonobjc public static func create() -> NSManagedObject {
        create(context: NSManagedObjectContext.defaultContext)
    }

    @nonobjc public static func create(context: NSManagedObjectContext) -> NSManagedObject {
        let o = NSEntityDescription.insertNewObject(forEntityName: entityName(), into: context) as NSManagedObject
        if let idprop = autoIncrementingId() {
            o.setPrimitiveValue(NSNumber(value: nextId() as Int), forKey: idprop)
        }
        return o
    }

    @nonobjc public static func create(properties: [String: Any]) -> NSManagedObject {
        create(properties, context: NSManagedObjectContext.defaultContext)
    }

    @nonobjc public static func create(_ properties: [String: Any], context: NSManagedObjectContext) -> NSManagedObject {
        let newEntity: NSManagedObject = create(context: context)
        newEntity.update(properties)
        if let idprop = autoIncrementingId() {
            if newEntity.primitiveValue(forKey: idprop) == nil {
                newEntity.setPrimitiveValue(NSNumber(value: nextId() as Int), forKey: idprop)
            }
        }
        return newEntity
    }

    public static func autoIncrements() -> Bool {
        autoIncrementingId() != nil
    }

    public static func nextId() -> Int {
        let key = "SwiftRecord-" + entityName() + "-ID"
        if autoIncrementingId() != nil {
            let id = UserDefaults.standard.integer(forKey: key)
            UserDefaults.standard.set(id + 1, forKey: key)
            return id
        }
        return 0
    }

	public func update(_ properties: [String: Any]) {
        if properties.isEmpty {
            return
        }
        let context = managedObjectContext ?? NSManagedObjectContext.defaultContext
        let transformed = type(of: self).transformProperties(properties, context: context)
        // Finish
        for (key, value) in transformed {
            willChangeValue(forKey: key)
            setSafeValue(value as AnyObject?, forKey: key)
            didChangeValue(forKey: key)
        }
    }

    public static func save() -> Bool {
        do {
            print("Object saveContext: \(NSManagedObjectContext.defaultContext.debugDescription)")

            try NSManagedObjectContext.defaultContext.save()
            return true
        } catch let e as NSError {
            print("Save Error: \(e)")
            return false
        }
    }

	public func save() -> Bool {
        saveTheContext()
    }

	public func delete() {
        managedObjectContext?.delete(self)
    }

    public static func deleteAll() {
        deleteAll(NSManagedObjectContext.defaultContext)
    }

    public static func deleteAll(_ context: NSManagedObjectContext) {
        for o in all(context: context) {
            o.delete()
        }
    }

    public class func autoIncrementingId() -> String? {
        nil
    }

    public static func entityName() -> String {
        var name = NSStringFromClass(self)
        if name.contains(".") {
            let comp = name.split { $0 == "." }.map { String($0) }
            if comp.count > 1 {
                name = comp.last!
            }
        }
        if name.contains("_") {
            var comp = name.split { $0 == "_" }.map { String($0) }
            var last = ""
            var remove = -1
            for (i, s) in comp.reversed().enumerated() {
                if last == s {
                    remove = i
                }
                last = s
            }
            if remove > -1 {
                comp.remove(at: remove)
                name = comp.joined(separator: "_")
            }
        }
        return name
    }

    // Private

    fileprivate static func transformProperties(_ properties: [String: Any], context: NSManagedObjectContext) -> [String: Any] {
        let entity = NSEntityDescription.entity(forEntityName: entityName(), in: context)!
        let attrs = entity.attributesByName
        let rels = entity.relationshipsByName

        var transformed = [String: Any]()
        for (key, value) in properties {
            let localKey = keyForRemoteKey(key, context: context)
            if attrs[localKey] != nil {
                transformed[localKey] = value
            } else if let rel = rels[localKey] {
                if SwiftRecord.generateRelationships {
                    if rel.isToMany {
                        if let array = value as? [[String: Any]] {
                            transformed[localKey] = generateSet(rel, array: array, context: context)
                        } else {
                            #if DEBUG
                                print("Invalid value for relationship generation in \(NSStringFromClass(self)).\(localKey)")
                                print(value)
                            #endif
                        }
                    } else if let dict = value as? [String: Any] {
                        transformed[localKey] = generateObject(rel, dict: dict, context: context)
                    } else {
                        #if DEBUG
                            print("Invalid value for relationship generation in \(NSStringFromClass(self)).\(localKey)")
                            print(value)
                        #endif
                    }
                }
            }
        }
        return transformed
    }

    fileprivate static func predicate(_ properties: [String: Any]?) -> NSPredicate? {
        guard let properties = properties else {
            return nil
        }

        var preds = [NSPredicate]()
        for (key, value) in properties {
            preds.append(NSPredicate(format: "%K = %@", argumentArray: [key, value]))
        }
        return NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: preds)
    }

    fileprivate static func predicate(_ condition: String?, args: [Any]? = nil) -> NSPredicate? {
        guard let condition = condition else {
            return nil
        }

        return NSPredicate(format: condition, argumentArray: args)
    }

    fileprivate static func sortDescriptor(_ dict: [String: Any]) -> NSSortDescriptor {
        let isAscending = (dict.values.first as! String).uppercased() != "DESC"
        return NSSortDescriptor(key: dict.keys.first!, ascending: isAscending)
    }

    fileprivate static func sortDescriptor(_ string: String) -> NSSortDescriptor {
        var key = string
        let components = string.split { $0 == " " }.map { String($0) }
        var isAscending = true
        if components.count > 1 {
            key = components[0]
            isAscending = components[1] == "ASC"
        }
        return NSSortDescriptor(key: key, ascending: isAscending)
    }

    fileprivate static func sortDescriptors(_ s: String?) -> [NSSortDescriptor]? {
        guard let s = s else {
            return nil
        }

        let components = s.split { $0 == "," }.map { String($0) }
        var ds = [NSSortDescriptor]()
        for sub in components {
            ds.append(sortDescriptor(sub))
        }
        return ds
    }

    fileprivate static func sortDescriptors(_ ds: [[String: Any]]?) -> [NSSortDescriptor]? {
        guard let ds = ds else {
            return nil
        }

        var ret = [NSSortDescriptor]()
        for d in ds {
            ret.append(sortDescriptor(d))
        }
        return ret
    }

    fileprivate static func createFetchRequest(_ context: NSManagedObjectContext) -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = NSEntityDescription.entity(forEntityName: entityName(), in: context)
        return request
    }

    fileprivate static func fetch(query: String?, context: NSManagedObjectContext, sortQuery: String?, limit: Int?, args: [Any]? = nil) -> [NSManagedObject] {
        let request = createFetchRequest(context)

        request.predicate = predicate(query, args: args)
        request.sortDescriptors = sortDescriptors(sortQuery)

        if let lim = limit {
            request.fetchLimit = lim
        }

        return fetch(request: request, context: context)
    }

    fileprivate static func fetch(query: String?, context: NSManagedObjectContext, sortConditions: [[String: Any]]?, limit: Int?, args: [Any]? = nil) -> [NSManagedObject] {
        let request = createFetchRequest(context)

        request.predicate = predicate(query, args: args)
        request.sortDescriptors = sortDescriptors(sortConditions)

        if let lim = limit {
            request.fetchLimit = lim
        }

        return fetch(request: request, context: context)
    }

    fileprivate static func fetch(query: String?, context: NSManagedObjectContext, sortCondition: [String: Any]?, limit: Int?, args: [Any]? = nil) -> [NSManagedObject] {
        var conditions: [[String: Any]]?

        if let condition = sortCondition {
            conditions = [condition]
        }

        return fetch(query: query, context: context, sortConditions: conditions, limit: limit, args: args)
    }

    fileprivate static func fetch(query: String?, context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor]?, limit: Int?, args: [Any]? = nil) -> [NSManagedObject] {
        let request = createFetchRequest(context)

        request.predicate = predicate(query, args: args)
        request.sortDescriptors = sortDescriptors

        if let lim = limit {
            request.fetchLimit = lim
        }

        return fetch(request: request, context: context)
    }

    fileprivate static func fetch(properties: [String: Any]?, context: NSManagedObjectContext, sortQuery: String?, limit: Int?) -> [NSManagedObject] {
        let request = createFetchRequest(context)

        request.predicate = predicate(properties)
        request.sortDescriptors = sortDescriptors(sortQuery)

        if let lim = limit {
            request.fetchLimit = lim
        }

        return fetch(request: request, context: context)
    }

    fileprivate static func fetch(properties: [String: Any]?, context: NSManagedObjectContext, sortConditions: [[String: Any]]?, limit: Int?) -> [NSManagedObject] {
        let request = createFetchRequest(context)

        request.predicate = predicate(properties)
        request.sortDescriptors = sortDescriptors(sortConditions)

        if let lim = limit {
            request.fetchLimit = lim
        }
        print("Fetch context: \(context.debugDescription)")
        print("Fetch request: \(request.debugDescription)")
        return fetch(request: request, context: context)
    }

    fileprivate static func fetch(properties: [String: Any]?, context: NSManagedObjectContext, sortCondition: [String: Any]?, limit: Int?) -> [NSManagedObject] {
        var conditions: [[String: Any]]?

        if let condition = sortCondition {
            conditions = [condition]
        }

        return fetch(properties: properties, context: context, sortConditions: conditions, limit: limit)
    }

    fileprivate static func fetch(properties: [String: Any]?, context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor]?, limit: Int?) -> [NSManagedObject] {
        let request = createFetchRequest(context)

        request.predicate = predicate(properties)
        request.sortDescriptors = sortDescriptors

        if let lim = limit {
            request.fetchLimit = lim
        }

        return fetch(request: request, context: context)
    }

    fileprivate static func fetch(predicate: NSPredicate?, context: NSManagedObjectContext, sortQuery: String?, limit: Int?) -> [NSManagedObject] {
        let request = createFetchRequest(context)

        request.predicate = predicate
        request.sortDescriptors = sortDescriptors(sortQuery)

        if let lim = limit {
            request.fetchLimit = lim
        }

        return fetch(request: request, context: context)
    }

    fileprivate static func fetch(predicate: NSPredicate?, context: NSManagedObjectContext, sortConditions: [[String: Any]]?, limit: Int?) -> [NSManagedObject] {
        let request = createFetchRequest(context)

        request.predicate = predicate
        request.sortDescriptors = sortDescriptors(sortConditions)

        if let lim = limit {
            request.fetchLimit = lim
        }

        return fetch(request: request, context: context)
    }

    fileprivate static func fetch(predicate: NSPredicate?, context: NSManagedObjectContext, sortCondition: [String: Any]?, limit: Int?) -> [NSManagedObject] {
        var conditions: [[String: Any]]?

        if let condition = sortCondition {
            conditions = [condition]
        }

        return fetch(predicate: predicate, context: context, sortConditions: conditions, limit: limit)
    }

    fileprivate static func fetch(predicate: NSPredicate?, context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor]?, limit: Int?) -> [NSManagedObject] {
        let request = createFetchRequest(context)

        request.predicate = predicate
        request.sortDescriptors = sortDescriptors

        if let lim = limit {
            request.fetchLimit = lim
        }

        return fetch(request: request, context: context)
    }

    fileprivate static func fetch(request: NSFetchRequest<NSFetchRequestResult>, context: NSManagedObjectContext) -> [NSManagedObject] {
        var result: [NSManagedObject]

        do {
            var fetchResult: [AnyObject]
            try fetchResult = context.fetch(request)

            if let fetchResultTyped = fetchResult as? [NSManagedObject] {
                result = fetchResultTyped
            } else {
                throw NSError(domain: "Fetch results unable to be casted to [NSManagedObject]", code: 0, userInfo: nil)
            }
        } catch let error as NSError {
            print("Error executing fetch request \(request): " + error.description)
            result = [NSManagedObject]()
        }

        return result
    }

    fileprivate static func countForFetch(_ predicate: NSPredicate?, context: NSManagedObjectContext) -> Int {
        let request = createFetchRequest(context)
        request.predicate = predicate

        return try! context.count(for: request)
    }

    fileprivate static func count(_ predicate: NSPredicate, context: NSManagedObjectContext) -> Int {
        let request = createFetchRequest(context)
        request.predicate = predicate
        return try! context.count(for: request)
    }

    private func saveTheContext() -> Bool {
        if managedObjectContext == nil || !managedObjectContext!.hasChanges {
            return true
        }

        do {
            try managedObjectContext!.save()
        } catch let error as NSError {
            print("Unresolved error in saving context for entity:")
            print(self)
            print("!\nError: " + error.debugDescription)
            return false
        }

        return true
    }

    private func setSafeValue(_ value: AnyObject?, forKey key: String) {
        if value == nil {
            setNilValueForKey(key)
            return
        }
        let val: AnyObject = value!
        if let attr = entity.attributesByName[key] {
            let attrType = attr.attributeType
            if attrType == NSAttributeType.stringAttributeType, value is NSNumber {
                setPrimitiveValue((val as! NSNumber).stringValue, forKey: key)
            } else if let s = val as? String {
                if isIntegerAttributeType(attrType) {
                    setPrimitiveValue(NSNumber(value: val.intValue as Int), forKey: key)
                    return
                } else if attrType == NSAttributeType.booleanAttributeType {
                    setPrimitiveValue(NSNumber(value: val.boolValue as Bool), forKey: key)
                    return
                } else if attrType == NSAttributeType.floatAttributeType {
                    setPrimitiveValue(NSNumber(value: val.doubleValue), forKey: key)
                    return
                } else if attrType == NSAttributeType.dateAttributeType {
                    setPrimitiveValue(type(of: self).dateFormatter.date(from: s), forKey: key)
                    return
                }
            }
        }
        setPrimitiveValue(value, forKey: key)
    }

    private func isIntegerAttributeType(_ attrType: NSAttributeType) -> Bool {
        attrType == NSAttributeType.integer16AttributeType || attrType == NSAttributeType.integer32AttributeType || attrType == NSAttributeType.integer64AttributeType
    }

    fileprivate static var dateFormatter: DateFormatter {
        if let df = _dateFormatter {
            return df
        } else {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss z"
            _dateFormatter = df
            return _dateFormatter ?? df
        }
    }

    fileprivate static var _dateFormatter: DateFormatter?
}

extension NSManagedObject {
	public class func mappings() -> [String: String] {
        [String: String]()
    }

    public static func keyForRemoteKey(_ remote: String, context: NSManagedObjectContext) -> String {
        if let s = cachedMappings[remote] {
            return s
        }
        let entity = NSEntityDescription.entity(forEntityName: entityName(), in: context)!
        let properties = entity.propertiesByName
        if properties[remote] != nil {
            _cachedMappings![remote] = remote
            return remote
        }

        let camelCased = remote.camelCase
        if properties[camelCased] != nil {
            _cachedMappings![remote] = camelCased
            return camelCased
        }
        _cachedMappings![remote] = remote
        return remote
    }

    fileprivate static var cachedMappings: [String: String] {
        if let m = _cachedMappings {
            return m
        } else {
            var m = [String: String]()
            for (key, value) in mappings() {
                m[value] = key
            }
            _cachedMappings = m
            return m
        }
    }

    fileprivate static var _cachedMappings: [String: String]?

    fileprivate static func generateSet(_ rel: NSRelationshipDescription, array: [[String: Any]], context: NSManagedObjectContext) -> NSSet {
        var cls: NSManagedObject.Type?
        if !SwiftRecord.nameToEntities.isEmpty {
            cls = SwiftRecord.nameToEntities[rel.destinationEntity!.managedObjectClassName]
        }
        if cls == nil {
            cls = (NSClassFromString(rel.destinationEntity!.managedObjectClassName) as! NSManagedObject.Type)
        } else {
            print("Got class name from entity setup")
        }
        let set = NSMutableSet()
        for d in array {
            set.add(cls!.findOrCreate(d, context: context))
        }
        return set
    }

    fileprivate static func generateObject(_ rel: NSRelationshipDescription, dict: [String: Any], context: NSManagedObjectContext) -> NSManagedObject {
        let entity = rel.destinationEntity!

        let cls: NSManagedObject.Type = NSClassFromString(entity.managedObjectClassName) as! NSManagedObject.Type
        return cls.findOrCreate(dict, context: context)
    }

    public static func primaryKey() -> String {
        assertionFailure("Primary key undefined in \(NSStringFromClass(self)). Override primaryKey if you want to support automatic creation, otherwise disable this feature")
        return ""
    }
}

private extension String {
    var camelCase: String {
        let spaced = replacingOccurrences(of: "_", with: " ")
        let capitalized = spaced.capitalized
        let spaceless = capitalized.replacingOccurrences(of: " ", with: "")
        return spaceless.replacingCharacters(in: spaceless.startIndex ..< spaceless.index(after: spaceless.startIndex), with: "\(spaceless[spaceless.startIndex])".lowercased())
    }
}

extension NSObject {
    // create a static method to get a swift class for a string name
    class func swiftClassFromString(_ className: String) -> AnyClass! {
        // get the project name
        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            // generate the full name of your class (take a look into your "YourProject-swift.h" file)
            let classStringName = "_TtC\(appName.utf16.count)\(appName)\(className.count)\(className)"
            // return the class!

            return NSClassFromString(classStringName)
        }
        return nil
    }
}
