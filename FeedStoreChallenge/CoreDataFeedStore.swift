//
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {
	private static let modelName = "FeedStore"
	private static let model = NSManagedObjectModel(name: modelName, in: Bundle(for: CoreDataFeedStore.self))

	private let container: NSPersistentContainer
	private let context: NSManagedObjectContext

	struct ModelNotFound: Error {
		let modelName: String
	}

	public init(storeURL: URL) throws {
		guard let model = CoreDataFeedStore.model else {
			throw ModelNotFound(modelName: CoreDataFeedStore.modelName)
		}

		container = try NSPersistentContainer.load(
			name: CoreDataFeedStore.modelName,
			model: model,
			url: storeURL
		)
		context = container.newBackgroundContext()
	}

	public func retrieve(completion: @escaping RetrievalCompletion) {
		perform { context in
			let request = ManagedCache.fetchRequest()
			request.fetchLimit = 1
			do {
				guard let cache = try context.fetch(request).first as? ManagedCache else {
					completion(.empty)
					return
				}

				guard let feed = Array(cache.feed) as? [ManagedFeedImage] else {
					completion(.empty)
					return
				}

				var localFeed = [LocalFeedImage]()
				for image in feed {
					let localImage = LocalFeedImage(id: image.id, description: image.imageDescription, location: image.location, url: image.url)
					localFeed.append(localImage)
				}

				completion(.found(feed: localFeed, timestamp: cache.timestamp))
			} catch {
				completion(.empty)
			}
		}
	}

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		perform { context in
			let newCache = NSEntityDescription.insertNewObject(forEntityName: String(describing: ManagedCache.self), into: context) as! ManagedCache
			newCache.timestamp = timestamp
			newCache.feed = ManagedFeedImage.images(from: feed, in: context)

			do {
				try context.save()
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}

	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		fatalError("Must be implemented")
	}

	private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
		let context = self.context
		context.perform { action(context) }
	}
}

@objc(ManagedCache)
internal class ManagedCache: NSManagedObject {
	@NSManaged internal var timestamp: Date
	@NSManaged internal var feed: NSOrderedSet
}

@objc(ManagedFeedImage)
internal class ManagedFeedImage: NSManagedObject {
	@NSManaged internal var id: UUID
	@NSManaged internal var imageDescription: String?
	@NSManaged internal var location: String?
	@NSManaged internal var url: URL

	@NSManaged internal var cache: ManagedCache
}

extension ManagedFeedImage {
	class func images(from images: [LocalFeedImage], in context: NSManagedObjectContext) -> NSOrderedSet {
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

private class FeedImageMapper {}
