import CoreData
import Foundation

struct LMItemModel: Identifiable, Equatable {
    let id: String
    let payload: String
    let createdAt: Date
    let updatedAt: Date
}

enum LMRepositoryError: LocalizedError {
    case itemNotFound(String)

    var errorDescription: String? {
        switch self {
        case let .itemNotFound(id):
            return "LM item not found for id \(id)."
        }
    }
}

@MainActor
final class LMRepository {
    private let viewContext: NSManagedObjectContext

    init(persistenceController: LMPersistenceController) {
        self.viewContext = persistenceController.container.viewContext
    }

    @discardableResult
    func save(id: String, payload: String) throws -> LMItemModel {
        let now = Date()
        let item = try fetchItem(id: id) ?? Item(context: viewContext)
        item.id = id
        item.payload = payload
        item.createdAt = item.createdAt ?? now
        item.updatedAt = now
        item.timestamp = now

        try viewContext.saveIfNeeded()
        return makeModel(from: item)
    }

    func get(id: String) throws -> LMItemModel? {
        try fetchItem(id: id).map(makeModel(from:))
    }

    func getAll() throws -> [LMItemModel] {
        let request = makeFetchRequest()
        return try viewContext.fetch(request).map(makeModel(from:))
    }

    @discardableResult
    func modify(id: String, payload: String) throws -> LMItemModel {
        guard let item = try fetchItem(id: id) else {
            throw LMRepositoryError.itemNotFound(id)
        }

        item.payload = payload
        item.updatedAt = Date()
        item.timestamp = item.updatedAt

        try viewContext.saveIfNeeded()
        return makeModel(from: item)
    }

    private func makeFetchRequest() -> NSFetchRequest<Item> {
        let request = Item.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "updatedAt", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false),
            NSSortDescriptor(key: "timestamp", ascending: false)
        ]
        return request
    }

    private func fetchItem(id: String) throws -> Item? {
        let request = makeFetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id)
        return try viewContext.fetch(request).first
    }

    private func makeModel(from item: Item) -> LMItemModel {
        let createdAt = item.createdAt ?? item.timestamp ?? Date()
        let updatedAt = item.updatedAt ?? item.timestamp ?? createdAt

        return LMItemModel(
            id: item.id ?? "",
            payload: item.payload ?? "",
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private extension NSManagedObjectContext {
    var hasPersistentChanges: Bool {
        !insertedObjects.isEmpty
            || !deletedObjects.isEmpty
            || updatedObjects.contains(where: { !$0.changedValues().isEmpty })
    }

    func saveIfNeeded() throws {
        guard hasPersistentChanges else { return }
        try save()
    }
}
