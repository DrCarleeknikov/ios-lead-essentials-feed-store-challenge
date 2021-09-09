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

			do {
				if let cache = try ManagedCache.find(in: context) {
					completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
				} else {
					completion(.empty)
				}
			} catch {
				completion(.failure(error))
			}
		}
	}

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		perform { context in
			do {
				let newCache = try ManagedCache.newUniqueInstance(in: context)
				newCache.timestamp = timestamp
				newCache.feed = ManagedFeedImage.images(from: feed, in: context, with: newCache)

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

extension ManagedCache {
	static func newUniqueInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
		try find(in: context).map(context.delete)
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

@objc(ManagedFeedImage)
internal class ManagedFeedImage: NSManagedObject {
	@NSManaged internal var id: UUID
	@NSManaged internal var imageDescription: String?
	@NSManaged internal var location: String?
	@NSManaged internal var url: URL

	@NSManaged internal var cache: ManagedCache
}

extension ManagedFeedImage {
	class func images(from images: [LocalFeedImage], in context: NSManagedObjectContext, with cache: ManagedCache) -> NSOrderedSet {
		var managedFeed = [ManagedFeedImage]()
		for image in images {
			let managedImage = ManagedFeedImage(context: context)
			managedImage.id = image.id
			managedImage.imageDescription = image.description
			managedImage.location = image.location
			managedImage.url = image.url
			managedImage.cache = cache
			managedFeed.append(managedImage)
		}
		return NSOrderedSet(array: managedFeed)
	}
}
