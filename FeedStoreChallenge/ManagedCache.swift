//
//  ManagedCache.swift
//  FeedStoreChallenge
//
//  Created by Joshua Bryson on 9/9/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

@objc(ManagedCache)
class ManagedCache: NSManagedObject {
	@NSManaged var timestamp: Date
	@NSManaged var feed: NSOrderedSet
}

extension ManagedCache {
	static func deletePreviousCache(in context: NSManagedObjectContext) throws {
		try find(in: context).map(context.delete).map(context.save)
	}

	static func newUniqueInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
		try deletePreviousCache(in: context)
		return NSEntityDescription.insertNewObject(forEntityName: String(describing: ManagedCache.self), into: context) as! ManagedCache
	}

	class func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
		let request = ManagedCache.fetchRequest()
		request.fetchLimit = 1
		return try context.fetch(request).first as? ManagedCache
	}

	var localFeed: [LocalFeedImage] {
		let feed = Array(feed) as! [ManagedFeedImage]

		var localFeed = [LocalFeedImage]()
		for image in feed {
			let localImage = LocalFeedImage(id: image.id, description: image.imageDescription, location: image.location, url: image.url)
			localFeed.append(localImage)
		}
		return localFeed
	}
}
