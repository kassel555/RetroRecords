//
//  UserManager.swift
//  RetroRecords
//
//  Manages users and current user selection
//

import Foundation

class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published var users: [User] = []
    @Published var currentUser: User?

    private let usersKey = "retrorecords_users"
    private let currentUserIdKey = "retrorecords_current_user_id"

    private init() {
        loadUsers()
        loadCurrentUser()
    }

    // MARK: - User Management

    func addUser(_ user: User) {
        users.append(user)
        saveUsers()
    }

    func deleteUser(_ user: User) {
        users.removeAll { $0.id == user.id }
        if currentUser?.id == user.id {
            currentUser = nil
            UserDefaults.standard.removeObject(forKey: currentUserIdKey)
        }
        saveUsers()
        // Also delete user's albums file
        deleteUserAlbums(userId: user.id)
    }

    func updateUser(_ user: User) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
            saveUsers()
            if currentUser?.id == user.id {
                currentUser = user
            }
        }
    }

    func selectUser(_ user: User) {
        currentUser = user
        UserDefaults.standard.set(user.id.uuidString, forKey: currentUserIdKey)
    }

    func logout() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: currentUserIdKey)
    }

    // MARK: - Persistence

    private func loadUsers() {
        guard let data = UserDefaults.standard.data(forKey: usersKey),
              let decoded = try? JSONDecoder().decode([User].self, from: data) else {
            return
        }
        users = decoded
    }

    private func saveUsers() {
        guard let data = try? JSONEncoder().encode(users) else { return }
        UserDefaults.standard.set(data, forKey: usersKey)
    }

    private func loadCurrentUser() {
        guard let idString = UserDefaults.standard.string(forKey: currentUserIdKey),
              let userId = UUID(uuidString: idString),
              let user = users.first(where: { $0.id == userId }) else {
            return
        }
        currentUser = user
    }

    private func deleteUserAlbums(userId: UUID) {
        let fileName = "albums_\(userId.uuidString).json"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
