//
//  UserSelectionView.swift
//  RetroRecords
//
//  User selection / login screen
//

import SwiftUI

struct UserSelectionView: View {
    @ObservedObject var userManager: UserManager
    @Environment(\.colorScheme) var colorScheme

    @State private var showingAddUser = false
    @State private var newUserName = ""
    @State private var selectedEmoji = "🎵"
    @State private var showingDeleteAlert = false
    @State private var userToDelete: User?

    var body: some View {
        ZStack {
            RetroTheme.adaptiveBackgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "opticaldisc.fill")
                        .font(.system(size: 70))
                        .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))

                    Text("RetroRecords")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))

                    Text("Who's collecting today?")
                        .font(.subheadline)
                        .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                }
                .padding(.top, 40)

                // Users list
                if userManager.users.isEmpty {
                    emptyStateView
                } else {
                    usersGridView
                }

                Spacer()

                // Add user button
                Button {
                    showingAddUser = true
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Add User")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.bottom, 30)
            }
            .padding()
        }
        .sheet(isPresented: $showingAddUser) {
            addUserSheet
        }
        .alert("Delete User?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let user = userToDelete {
                    userManager.deleteUser(user)
                }
            }
        } message: {
            if let user = userToDelete {
                Text("This will delete \(user.name)'s entire collection. This cannot be undone.")
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 50))
                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme).opacity(0.5))

            Text("No users yet")
                .font(.headline)
                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))

            Text("Add a user to start tracking your vinyl collection")
                .font(.caption)
                .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - Users Grid

    private var usersGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 16) {
                ForEach(userManager.users) { user in
                    UserCard(user: user, colorScheme: colorScheme) {
                        userManager.selectUser(user)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            userToDelete = user
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Add User Sheet

    private var addUserSheet: some View {
        NavigationStack {
            ZStack {
                RetroTheme.adaptiveBackgroundGradient(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Avatar picker
                    VStack(spacing: 12) {
                        Text(selectedEmoji)
                            .font(.system(size: 80))

                        Text("Choose an avatar")
                            .font(.caption)
                            .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                            ForEach(User.avatarOptions, id: \.self) { emoji in
                                Button {
                                    selectedEmoji = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.title)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            selectedEmoji == emoji
                                                ? RetroTheme.adaptiveAccent(for: colorScheme).opacity(0.3)
                                                : RetroTheme.adaptiveCardBackground(for: colorScheme)
                                        )
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                        .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
                        .cornerRadius(16)
                    }

                    // Name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(RetroTheme.adaptiveTextSecondary(for: colorScheme))

                        TextField("Enter your name", text: $newUserName)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
                            .cornerRadius(12)
                            .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                    }

                    Spacer()

                    // Create button
                    Button {
                        createUser()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Create User")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(newUserName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(newUserName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                }
                .padding()
            }
            .navigationTitle("New User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddUser = false
                        resetForm()
                    }
                    .foregroundColor(RetroTheme.adaptiveAccent(for: colorScheme))
                }
            }
        }
    }

    // MARK: - Actions

    private func createUser() {
        let name = newUserName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let user = User(name: name, avatarEmoji: selectedEmoji)
        userManager.addUser(user)
        userManager.selectUser(user)
        showingAddUser = false
        resetForm()
    }

    private func resetForm() {
        newUserName = ""
        selectedEmoji = "🎵"
    }
}

// MARK: - User Card

struct UserCard: View {
    let user: User
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Text(user.avatarEmoji)
                    .font(.system(size: 50))

                Text(user.name)
                    .font(.headline)
                    .foregroundColor(RetroTheme.adaptiveTextPrimary(for: colorScheme))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background(RetroTheme.adaptiveCardBackground(for: colorScheme))
            .cornerRadius(16)
            .shadow(color: RetroTheme.cardShadow(for: colorScheme), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    UserSelectionView(userManager: UserManager.shared)
}
