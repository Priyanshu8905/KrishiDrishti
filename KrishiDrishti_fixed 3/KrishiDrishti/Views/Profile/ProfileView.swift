// Views/Profile/ProfileView.swift
// KrishiDrishti — Farmer profile view + edit sheet

import SwiftUI

// MARK: - Profile Sheet
struct ProfileView: View {
    @ObservedObject var profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false

    var body: some View {
        NavigationStack {
            List {
                // Header section
                Section {
                    HStack(spacing: 16) {
                        Text(profile.avatar)
                            .font(.system(size: 64))
                            .frame(width: 80, height: 80)
                            .background(AppTheme.greenSoft, in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                            if !profile.village.isEmpty || !profile.state.isEmpty {
                                Label(
                                    [profile.village, profile.state].filter{!$0.isEmpty}.joined(separator: ", "),
                                    systemImage: "mappin.circle.fill"
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .labelStyle(.titleAndIcon)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Farm details section
                if !profile.farmSize.isEmpty || !profile.crops.isEmpty {
                    Section("Farm Info") {
                        if !profile.farmSize.isEmpty {
                            Label {
                                HStack {
                                    Text("Farm Size")
                                    Spacer()
                                    Text(profile.farmSize + " acres")
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "square.grid.2x2.fill")
                                    .foregroundStyle(AppTheme.green)
                            }
                        }
                        if !profile.crops.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("My Crops", systemImage: "leaf.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .labelStyle(.titleAndIcon)
                                FlowTags(items: profile.crops)
                                    .padding(.top, 2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Contact section
                if !profile.phone.isEmpty {
                    Section("Contact") {
                        Label {
                            HStack {
                                Text("Phone")
                                Spacer()
                                Text(profile.phone)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "phone.fill")
                                .foregroundStyle(AppTheme.green)
                        }
                    }
                }

                // Edit button
                Section {
                    Button {
                        showEdit = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Edit Profile", systemImage: "pencil")
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.green)
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.green)
                }
            }
        }
        .sheet(isPresented: $showEdit) { ProfileEditView(profile: profile) }
    }
}

// MARK: - ProfileEditView
struct ProfileEditView: View {
    @ObservedObject var profile: UserProfile
    @Environment(\.dismiss) var dismiss

    @State private var n = ""
    @State private var v = ""
    @State private var s = ""
    @State private var f = ""
    @State private var p = ""
    @State private var crops: Set<String> = []
    @State private var avatar = 0

    var body: some View {
        NavigationStack {
            List {
                // Avatar picker
                Section {
                    VStack(spacing: 14) {
                        Text(UserProfile.avatars[safe: avatar] ?? "👨‍🌾")
                            .font(.system(size: 72))
                            .animation(.spring(response: 0.3), value: avatar)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(UserProfile.avatars.enumerated()), id: \.offset) { i, e in
                                    Button { withAnimation { avatar = i } } label: {
                                        Text(e).font(.system(size: 30))
                                            .frame(width: 52, height: 52)
                                            .background(
                                                avatar == i ? AppTheme.greenSoft : Color(uiColor: .tertiarySystemGroupedBackground),
                                                in: RoundedRectangle(cornerRadius: 12)
                                            )
                                            .overlay(RoundedRectangle(cornerRadius: 12)
                                                .stroke(avatar == i ? AppTheme.green : Color.clear, lineWidth: 2))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("Personal Info") {
                    HStack {
                        Label("Name", systemImage: "person.fill")
                            .foregroundStyle(.secondary)
                            .labelStyle(.iconOnly)
                            .frame(width: 28)
                        TextField("Your full name", text: $n)
                    }
                    HStack {
                        Label("Phone", systemImage: "phone.fill")
                            .foregroundStyle(.secondary)
                            .labelStyle(.iconOnly)
                            .frame(width: 28)
                        TextField("Mobile number", text: $p)
                            .keyboardType(.phonePad)
                    }
                }

                Section("Farm Details") {
                    HStack {
                        Label("Village", systemImage: "house.fill")
                            .foregroundStyle(.secondary)
                            .labelStyle(.iconOnly)
                            .frame(width: 28)
                        TextField("Village or town", text: $v)
                    }
                    HStack {
                        Label("State", systemImage: "map.fill")
                            .foregroundStyle(.secondary)
                            .labelStyle(.iconOnly)
                            .frame(width: 28)
                        Picker("State", selection: $s) {
                            Text("Select State").tag("")
                            ForEach(UserProfile.stateOptions, id: \.self) { st in
                                Text(st).tag(st)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(s.isEmpty ? Color(uiColor: .tertiaryLabel) : AppTheme.green)
                    }
                    HStack {
                        Label("Farm Size", systemImage: "square.grid.2x2.fill")
                            .foregroundStyle(.secondary)
                            .labelStyle(.iconOnly)
                            .frame(width: 28)
                        TextField("e.g. 2.5 acres", text: $f)
                    }
                }

                Section("My Crops") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(UserProfile.cropOptions, id: \.self) { crop in
                            let sel = crops.contains(crop)
                            Button {
                                withAnimation(.spring(response: 0.25)) {
                                    if sel { crops.remove(crop) } else { crops.insert(crop) }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: sel ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(sel ? AppTheme.green : Color(uiColor: .tertiaryLabel))
                                    Text(crop).font(.subheadline)
                                        .foregroundStyle(sel ? AppTheme.green : .primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    sel ? AppTheme.greenSoft : Color(uiColor: .tertiarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(sel ? AppTheme.green.opacity(0.4) : Color.clear, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { commit(); dismiss() }
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.green)
                }
            }
        }
        .onAppear { load() }
    }

    private func load() {
        n = profile.name; v = profile.village; s = profile.state
        f = profile.farmSize; p = profile.phone; avatar = profile.avatarIdx
        crops = Set(profile.crops)
    }
    private func commit() {
        profile.name = n; profile.village = v; profile.state = s
        profile.farmSize = f; profile.phone = p; profile.avatarIdx = avatar
        profile.crops = Array(crops)
    }
}
