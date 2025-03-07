//
//  ManagedFeedImage.swift
//  FeedStoreChallenge
//
//  Created by Joshua Bryson on 9/9/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

@objc(ManagedFeedImage)
final class ManagedFeedImage: NSManagedObject {
	@NSManaged var id: UUID
	@NSManaged var imageDescription: String?
	@NSManaged var location: String?
	@NSManaged var url: URL

	@NSManaged var cache: ManagedCache
}

extension ManagedFeedImage {
	static func images(from images: [LocalFeedImage], in context: NSManagedObjectContext) -> NSOrderedSet {
		var managedFeed = [ManagedFeedImage]()
		for image in images {
			let managedImage = ManagedFeedImage(context: context)
			managedImage.id = image.id
			managedImage.imageDescription = image.description
			managedImage.location = image.location
			managedImage.url = image.url
			managedFeed.append(managedImage)
		}
		return NSOrderedSet(array: managedFeed)
	}
}
