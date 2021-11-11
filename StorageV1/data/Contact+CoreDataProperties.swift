//
//  Contact+CoreDataProperties.swift
//  StorageV1
//
//  Created by Ray Chen on 10/31/21.
//
//

import Foundation
import CoreData


extension Contact {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Contact> {
        return NSFetchRequest<Contact>(entityName: "Contact")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var nickname: String?
    @NSManaged public var timeLatest: Date?
    @NSManaged public var identity: Identity?
    @NSManaged public var messages: NSSet?
    @NSManaged public var theirKey: PublicKey?

}

extension Contact {

	//	fetch the list of all messages of all
	 func fetchMessages() -> [Message] {let mss = self.messages
        return Array(_immutableCocoaArray: mss!)
	}
    
	
	// fetch the list of all contacts, opt = 0 for sort based on timeLatest
	static func fetchContacts(opt: Bool = true) -> [Contact] {
		let fr: NSFetchRequest<Contact> = Contact.fetchRequest()
		if (opt) {
			fr.sortDescriptors = [NSSortDescriptor(keyPath: \Contact.nickname, ascending: true)]
		} else {
			fr.sortDescriptors = [NSSortDescriptor(keyPath: \Contact.timeLatest, ascending:false)]
		}
		do {
			let cts = try PersistenceController.shared.container.viewContext.fetch(fr)
			return cts
		} catch {let nsError = error as NSError
			fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
		}
	}
	
	// search Contact based on uuid
	static func fetchContactWithID(id: UUID) -> Contact {
		let fr: NSFetchRequest<Contact> = Contact.fetchRequest()
		fr.predicate = NSPredicate(
			format: "id LIKE %@", id as CVarArg
		)
		do {
			let identity = (try PersistenceController.shared.container.viewContext.fetch(fr).first)!
            return identity
        } catch {let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
		}
	}
	
	//	retrive the latest message of all contacts
	func fetchLatests() -> [Message] {
		let contacts = Contact.fetchContacts(opt: false)
		var data = [Message]()
		for ct in contacts {
				data.append(ct.fetchMessages()[0])
		}
		return data
	}
	
	//	create message
    func createMessage(body: String) {
       let newMessage = Message(context: PersistenceController.shared.container.viewContext)
		newMessage.timeCreated = Date()
		newMessage.messageBody = body
		newMessage.contact = self
		newMessage.sentByMe = true
		newMessage.encryptAndQueue()
		PersistenceController.shared.save()
    }
	
	//	create contact (called in checkAndSearch() and TODO: QRContact())
    static func createContact(nn: String, key: PublicKey, id: UUID) -> Contact {
		let newContact = Contact(context: PersistenceController.shared.container.viewContext)
		newContact.nickname = nn
		newContact.id = id
		newContact.theirKey = key
		let identity = Identity.fetchIdentity()
		newContact.identity = identity
		PersistenceController.shared.save()
		return newContact
	}
	
	// search contact with id, if not exist, create with nn, id, key
	static func searchOrCreate(nn: String, key: PublicKey, id: UUID) -> Contact {
		let fr: NSFetchRequest<Contact> = Contact.fetchRequest()
		fr.predicate = NSPredicate(
			format: "id == %@", id as CVarArg
		)
		fr.fetchLimit = 1
		do {
			let ct = try PersistenceController.shared.container.viewContext.fetch(fr).first  ?? Contact.createContact(nn: nn, key: key, id: id)
			return ct
		} catch {let nsError = error as NSError
			fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
		}
	}
	
	//	delete
	func delete() {
		PersistenceController.shared.container.viewContext.delete(self)
	}

}

// MARK: Generated accessors for messages
extension Contact {

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: Message)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: Message)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)

}

extension Contact : Identifiable {

}
