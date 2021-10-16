//
//  ContentView.swift
//  StorageV1
//
//  Created by Ray Chen on 10/6/21.
//

import SwiftUI
import CoreData
import CryptorRSA

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
//	sort message with timeCreated, can be changed to different entity to test CRUD functions
//	to test other entities, they need to be fetchrequested as well
//    @FetchRequest(
////    	sort the messages by its timeCreated
//        sortDescriptors: [NSSortDescriptor(keyPath: \Message.timeCreated, ascending: true)],
//        animation: .default)
//    private var items: FetchedResults<Message>

    @FetchRequest(
//    	sort the identities by its nickname
        sortDescriptors: [NSSortDescriptor(keyPath: \Identity.nickname, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Identity>

//	add more var here to test create with multiple input item
    @State private var newItem = ""

    var body: some View {
        NavigationView {
			List {
//				Section(header: Text("Add message")) {
				Section(header: Text("Add identity")) {
					HStack{
//						add more TextField here to test create with multiple input item
//						TextField("New message", text: self.$newItem)
						TextField("New nickname", text: self.$newItem)
						Button(action: {
//						change the function here to test other CRUD
//							creatMessage(body: self.newItem)
//							createIdentity(nickname: self.newItem)
                            
                            
                            
						}){
							Image(systemName: "plus.circle.fill")
								 .foregroundColor(.blue)
								 .imageScale(.large)
						}
					}
				}
//                ForEach(items) { item in
//                //    change what to show here to check succeeful creation
//                //     Text(item.messageBody ?? "Unspecified")
//                     Text(item.publicKey?.keyBody ?? "Unspecified")
//                     Text(item.privateKey?.keyBody ?? "Unspecified")
//                // TODO: change show items to id attibutes
//                    }.onDelete(perform: deleteItem(offsets:))
                
                let result = encryptionTest()
                Text(result.testString)

                Text(String(result.decrypted.count))
                Text(result.decrypted)
                
			

			}
			.navigationTitle("Items")
		}
    }
//	sample functions for creation an entity
    private func createMessage(body: String) {
        withAnimation {
            let newMessage = Message(context: viewContext)
            newMessage.timeCreated = Date()
            newMessage.messageBody = body
            saveContext()
        }
    }
    
    private func encryptionTest() -> (testString:String,  decrypted: String) {
        let testString = "Hello World"
        
        var publicKeySec, privateKeySec: SecKey?
        let keyattribute = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String : 2048
        ] as CFDictionary
        SecKeyGeneratePair(keyattribute, &publicKeySec, &privateKeySec)
        
        var error: Unmanaged<CFError>?
		let dataPub = (SecKeyCopyExternalRepresentation(publicKeySec!, &error) as CFData?)!
		
		let attribute = [
			kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
			kSecAttrKeyClass as String : kSecAttrKeyClassPublic
		]
		let pubKey: SecKey = SecKeyCreateWithData(dataPub, attribute as CFDictionary, &error)!
		
		
        
        let bodyData: CFData = testString.data(using: .utf8)! as CFData
        
		let encrypted: Data = SecKeyCreateEncryptedData(pubKey, SecKeyAlgorithm.rsaEncryptionOAEPSHA1, bodyData, &error)! as Data
		let decrypted: Data = SecKeyCreateDecryptedData(privateKeySec!, SecKeyAlgorithm.rsaEncryptionOAEPSHA1, encrypted as CFData, &error)! as Data
		// TODO: handle nil case (if need to try decrypting every message)
        
        let str = String(decoding: decrypted, as: UTF8.self)
        
//        return (testString, encrypted.base64EncodedString(), str)
        return (testString,  str)
    }
    
    private func createIdentity(nickname: String) {
		withAnimation {
            let newIdentity = Identity(context: viewContext)
            newIdentity.nickname = nickname
			let result = createRSAKeyPair()
			createPrivateKey(kd: result.private, id: newIdentity)
			createPublicKey(kd: result.public, id: newIdentity, type: 0)
            saveContext()
        }
	}

//	generate new rsa key pair with random data
	private func createRSAKeyPair() -> (public:String, private:String) {
		var publicKeySec, privateKeySec: SecKey?
		let keyattribute = [
			kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
			kSecAttrKeySizeInBits as String : 2048
		] as CFDictionary
		SecKeyGeneratePair(keyattribute, &publicKeySec, &privateKeySec)
		
		var error: Unmanaged<CFError>?
		let dataPub = SecKeyCopyExternalRepresentation(publicKeySec!, &error) as Data?
		let dataPri = SecKeyCopyExternalRepresentation(privateKeySec!, &error) as Data?
		return (dataPub!.base64EncodedString(), dataPri!.base64EncodedString())
	}
	
	private func createPrivateKey(kd: String, id: Identity) {
		withAnimation {
            let newKey = PrivateKey(context: viewContext)
            newKey.keyBody = kd
            newKey.id = id
            saveContext()
        }
	}
	
//	need at least one of id (type 0, default), contact (type 1), eSender (type 2), mSender (type 3)
//	TODO: handle error cases
	private func createPublicKey(kd: String, id: Identity? = nil, contact: Contact? = nil, eSender: Encrypted? = nil, mSender: Message? = nil, type: Int = 0) {
		withAnimation {
            let newKey = PublicKey(context: viewContext)
            newKey.keyBody = kd
            switch type {
            case 0:
				newKey.id = id
			case 1:
				newKey.contact = contact
			case 2:
				newKey.encryptedSender = eSender
			case 3:
				newKey.messageSender = mSender
			default:
				newKey.id = id
			}
            
            saveContext()
        }
	}
	
//	save received encrypted
//	TODO: now assuming it's not mine, need to decrypt if possible
	private func createEncrypted(received: Encrypted, id: Identity) {
		withAnimation {
			received.id = id
		}
	}
	
private func retrievePublicKey(s: String) -> SecKey {
		let keyData = Data(s.utf8)
		let attribute = [
			kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
			kSecAttrKeyClass as String : kSecAttrKeyClassPublic
		]
		var error: Unmanaged<CFError>?
		let pubKey: SecKey = SecKeyCreateWithData(keyData as CFData, attribute as CFDictionary, &error)!
		return pubKey
	}
	
	private func retrievePrivateKey(s: String) -> SecKey {
		let keyData = Data(s.utf8)
		let attribute = [
			kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
			kSecAttrKeyClass as String : kSecAttrKeyClassPrivate
		]
		var error: Unmanaged<CFError>?
		let priKey: SecKey = SecKeyCreateWithData(keyData as CFData, attribute as CFDictionary, &error)!
		return priKey
	}

	
//	encrypt the message "I" create for sending to contact
//	TODO: need to change my own public key to the contact's public key
	private func createEncryptedFor(ms: Message, id: Identity) {
		withAnimation {
			let newEncrypted = Encrypted(context: viewContext)
			newEncrypted.id = id
			newEncrypted.messageType = ms.messageType
			newEncrypted.timeCreated = ms.timeCreated
			newEncrypted.senderKey = id.publicKey
			let publicKey: SecKey = retrievePublicKey(s: (id.publicKey?.keyBody)!)
			let bodyData: CFData = ms.messageBody!.data(using: .utf8)! as CFData
			var error: Unmanaged<CFError>?
			let encryptedBody: Data = SecKeyCreateEncryptedData(publicKey, SecKeyAlgorithm.rsaEncryptionOAEPSHA512, bodyData, &error)! as Data
			newEncrypted.encryptedBody = encryptedBody
			saveContext()
		}
	}
	
	private func decryptEncrypted(ec: Encrypted, id: Identity, contact: Contact) {
		withAnimation {
			let newMessage = Message(context: viewContext)
			newMessage.contact = contact
			newMessage.timeCreated = ec.timeCreated
			let privateKey: SecKey = retrievePrivateKey(s: (id.privateKey?.keyBody)!)
			var error: Unmanaged<CFError>?
			let decryptedBody: Data = SecKeyCreateDecryptedData(privateKey, SecKeyAlgorithm.rsaEncryptionOAEPSHA512, ec.encryptedBody! as CFData, &error)! as Data
			let dstring = String(decoding: decryptedBody, as: UTF8.self)
			newMessage.messageBody = dstring
			saveContext()
		}
	}
	
    
//  sample function to delete entity by swiping to left, more delete functions are needed like deleteMessage() below
    private func deleteItem(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }
    
//		sample functions for creation an entity
	private func deleteMessage(item: Message) {
		withAnimation {
			viewContext.delete(item)
			saveContext()
		}
	}
    
//    used at the end of all CRUD functions
    private func saveContext() {
		do {
                try viewContext.save()
            } catch {let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
	}
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
