//
//  Messages.swift
//  StorageV1
//
//  Created by Chen Gong on 11/27/21.
//

import Foundation

class Messages: ObservableObject {
    static let sharedInstance = Messages()
    
    @Published(persistingTo: "Message/messages.json") var messages: [UUID: Message2] = [:]
    
    init() {}
    
    init(messages: [Message2]) {
        self.messages = Dictionary(messages.map { ($0.id, $0) }, uniquingKeysWith: { k, _ in k })
    }
    
    subscript(id: UUID) -> Message2? {
        messages[id]
    }
    
    subscript(contactId: UUID?) -> [Message2] {
        messages.values
            .filter { $0.contactId == contactId }
            .sorted { $0.timeCreated < $1.timeCreated }
    }
    
}
