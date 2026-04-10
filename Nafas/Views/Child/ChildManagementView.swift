//
//  ChildManagementViews.swift
//  Nafas — Add Child, Edit Child, Add Peak Flow
//

import SwiftUI
import PhotosUI

// MARK: - AddChildView

struct AddChildView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = NafasStore.shared
    
    @State private var name = ""
    @State private var birthDate = Date()
    @State private var gender: ChildModel.Gender = .male
    @State private var isSaving = false
    @State private var createdChild: ChildModel?
    
    @State private var height = ""
    @State private var weight = ""
    @State private var relationship: ChildModel.GuardianRelationship = .mother
    @State private var selectedAvatarImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var emergencyPhoneNumbers: [String] = [""]
    @State private var newPhoneNumber = ""
    
    private let avatarColors = ["#1F6FEB", "#E0478A", "#34C759", "#AF52DE"]
    @State private var selectedColor = "#1F6FEB"
    
    // NEW VALIDATION: Checks if numbers are exactly 7 digits or entirely blank
    private var arePhonesValid: Bool {
        let activePhones = emergencyPhoneNumbers.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if activePhones.isEmpty { return true } // Allowed to be blank
        return activePhones.allSatisfy { $0.count == 9 } // Must be exactly 7 if filled
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && arePhonesValid
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Avatar preview with photo picker
                    VStack(spacing: 12) {
                        Button {
                            showPhotoPicker = true
                        } label: {
                            ZStack {
                                if let image = selectedAvatarImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color(hex: selectedColor))
                                        .frame(width: 80, height: 80)
                                    Text(name.isEmpty ? "?" : String(name.prefix(1)).uppercased())
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 2)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white)
                                )
                                .offset(x: 28, y: 28)
                        )
                        
                        Text(LocalizedStringKey("child_tap_to_add_photo"))
                            .font(.nafasCaption())
                            .foregroundStyle(Color.nafasTextMuted)
                        
                        Text(LocalizedStringKey("child_choose_color"))
                            .font(.nafasCaption())
                            .foregroundStyle(Color.nafasTextMuted)
                            .padding(.top, 4)
                        
                        HStack(spacing: 16) {
                            ForEach(avatarColors, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                            .shadow(color: .black.opacity(0.15), radius: 4)
                                    )
                                    .onTapGesture { selectedColor = color }
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Form fields
                    VStack(spacing: 16) {
                        NafasTextField(
                            labelKey: "child_full_name_label",
                            placeholderKey: "child_full_name_placeholder",
                            icon: "person",
                            text: $name
                        )
                        
                        // Birth Date picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text(LocalizedStringKey("child_birth_date_label"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.nafasTextPrimary)
                            
                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.nafasBackground)
                                        .overlay(RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.nafasDivider, lineWidth: 1))
                                )
                        }
                        
                        // Height and Weight with steppers
                        HStack(spacing: 12) {
                            stepperField(
                                label: NSLocalizedString("child_height_label", comment: ""),
                                value: $height,
                                range: 50...200
                            )
                            
                            stepperField(
                                label: NSLocalizedString("child_weight_label", comment: ""),
                                value: $weight,
                                range: 5...100
                            )
                        }
                        
                        // Guardian Relationship dropdown
                        VStack(alignment: .leading, spacing: 6) {
                            Text(LocalizedStringKey("child_relationship_label"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.nafasTextPrimary)
                            
                            Menu {
                                ForEach(ChildModel.GuardianRelationship.allCases, id: \.self) { rel in
                                    Button(rel.rawValue) {
                                        relationship = rel
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(relationship.rawValue)
                                        .foregroundStyle(Color.nafasTextPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(Color.nafasTextMuted)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.nafasBackground)
                                        .overlay(RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.nafasDivider, lineWidth: 1))
                                )
                            }
                        }
                        
                        // Gender picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text(LocalizedStringKey("child_gender_label"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.nafasTextPrimary)
                            HStack(spacing: 12) {
                                ForEach(ChildModel.Gender.allCases, id: \.self) { g in
                                    Button {
                                        gender = g
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: gender == g ? "largecircle.fill.circle" : "circle")
                                                .foregroundStyle(Color.nafasPrimary)
                                            Text(g.rawValue)
                                                .font(.system(size: 15))
                                                .foregroundStyle(Color.nafasTextPrimary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(gender == g ? Color.nafasPrimaryLight : Color.nafasBackground)
                                                .overlay(RoundedRectangle(cornerRadius: 12)
                                                    .strokeBorder(gender == g ? Color.nafasPrimary : Color.nafasDivider, lineWidth: 1))
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Emergency Phone Numbers
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey("child_emergency_phone_label"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.nafasTextPrimary)
                            
                            ForEach(emergencyPhoneNumbers.indices, id: \.self) { idx in
                                HStack(spacing: 8) {
                                    Image(systemName: "phone.fill")
                                        .foregroundStyle(Color.nafasPrimary)
                                        .frame(width: 20)
                                    
                                    TextField(NSLocalizedString("child_emergency_phone_placeholder", comment: ""), text: $emergencyPhoneNumbers[idx])
                                        .keyboardType(.numberPad)
                                        .font(.nafasBody())
                                        .onChange(of: emergencyPhoneNumbers[idx]) { oldValue, newValue in
                                            var filtered = newValue.filter { "0123456789".contains($0) }
                                            if filtered.count > 9 {
                                                filtered = String(filtered.prefix(9))
                                            }
                                            if emergencyPhoneNumbers[idx] != filtered {
                                                emergencyPhoneNumbers[idx] = filtered
                                            }
                                        }
                                    
                                    if emergencyPhoneNumbers.count > 1 {
                                        Button {
                                            emergencyPhoneNumbers.remove(at: idx)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(Color.nafasDanger)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.nafasBackground)
                                        .overlay(RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.nafasDivider, lineWidth: 1))
                                )
                            }
                            
                            // WARNING MESSAGE
                            if !arePhonesValid {
                                Text(LocalizedStringKey("Phone numbers must be exactly 9 digits."))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.nafasDanger)
                                    .padding(.top, 2)
                            }
                            
                            if emergencyPhoneNumbers.count < 3 {
                                Button {
                                    emergencyPhoneNumbers.append("")
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle")
                                        Text(LocalizedStringKey("child_add_emergency_phone"))
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.nafasPrimary)
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                    
                    // Save button
                    Button {
                        saveChild()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(LocalizedStringKey("add_child_save_button"))
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .disabled(!isValid || isSaving) // Enforces the exact 7 digit rule
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(isValid && !isSaving ? Color.nafasPrimary : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
            .background(Color.nafasBackground.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("add_child_nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundStyle(Color.nafasTextPrimary)
                    }
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedAvatarImage = image
                        }
                    }
                }
            }
            .fullScreenCover(item: $createdChild) { child in
                BluetoothConnectionView(child: child, isNewChild: true)
            }
            .onChange(of: createdChild) { oldValue, newValue in
                if newValue == nil && oldValue != nil {
                    dismiss()
                }
            }
        }
    }
    
    @ViewBuilder
    private func stepperField(label: String, value: Binding<String>, range: ClosedRange<Int>) -> some View {
        let intValue = Int(value.wrappedValue) ?? 0
        
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.nafasTextPrimary)
            
            HStack {
                Button {
                    let newValue = max(range.lowerBound, intValue - 1)
                    value.wrappedValue = "\(newValue)"
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.nafasPrimary)
                }
                
                TextField("0", text: value)
                    .font(.system(size: 18, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                
                Button {
                    let newValue = min(range.upperBound, intValue + 1)
                    value.wrappedValue = "\(newValue)"
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.nafasPrimary)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.nafasBackground)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.nafasDivider, lineWidth: 1))
            )
        }
    }
    
    private func saveChild() {
        isSaving = true
        
        let phones = emergencyPhoneNumbers.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
        let newChild = ChildModel(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            birthDate: birthDate,
            height: Int(height),
            weight: Int(weight),
            gender: gender,
            isConnected: false,
            deviceID: nil,
            condition: nil,
            avatarColor: selectedColor,
            guardianRelationship: relationship,
            avatarImageData: selectedAvatarImage?.jpegData(compressionQuality: 0.7),
            emergencyPhoneNumbers: phones
        )
        
        store.addChild(newChild)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            createdChild = newChild
        }
    }
}

// MARK: - EditChildView

struct EditChildView: View {
    let child: ChildModel
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = NafasStore.shared
    
    @State private var name: String
    @State private var birthDate: Date
    @State private var height: String
    @State private var weight: String
    @State private var gender: ChildModel.Gender
    @State private var relationship: ChildModel.GuardianRelationship
    @State private var selectedColor: String
    @State private var selectedAvatarImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var isSaving = false
    @State private var emergencyPhoneNumbers: [String]
    
    private let avatarColors = ["#1F6FEB", "#E0478A", "#34C759", "#AF52DE"]
    
    // NEW VALIDATION
    private var arePhonesValid: Bool {
        let activePhones = emergencyPhoneNumbers.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if activePhones.isEmpty { return true }
        return activePhones.allSatisfy { $0.count == 7 }
    }
    
    init(child: ChildModel) {
        self.child = child
        _name = State(initialValue: child.name)
        _birthDate = State(initialValue: child.birthDate)
        _height = State(initialValue: child.height.map { "\($0)" } ?? "")
        _weight = State(initialValue: child.weight.map { "\($0)" } ?? "")
        _gender = State(initialValue: child.gender)
        _relationship = State(initialValue: child.guardianRelationship)
        _selectedColor = State(initialValue: child.avatarColor)
        _emergencyPhoneNumbers = State(initialValue: child.emergencyPhoneNumbers.isEmpty ? [""] : child.emergencyPhoneNumbers)
        if let imageData = child.avatarImageData {
            _selectedAvatarImage = State(initialValue: UIImage(data: imageData))
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Avatar preview with photo picker
                    VStack(spacing: 12) {
                        Button {
                            showPhotoPicker = true
                        } label: {
                            ZStack {
                                if let image = selectedAvatarImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color(hex: selectedColor))
                                        .frame(width: 80, height: 80)
                                    Text(String(name.prefix(1)).uppercased())
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 2)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white)
                                )
                                .offset(x: 28, y: 28)
                        )
                        
                        Text(LocalizedStringKey("Tap to change photo"))
                            .font(.nafasCaption())
                            .foregroundStyle(Color.nafasTextMuted)
                        
                        HStack(spacing: 16) {
                            ForEach(avatarColors, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                            .shadow(color: .black.opacity(0.15), radius: 4)
                                    )
                                    .onTapGesture { selectedColor = color }
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        NafasTextField(labelKey: "child_full_name_label", placeholderKey: "child_full_name_placeholder", icon: "person", text: $name)
                        
                        // Birth Date picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text(LocalizedStringKey("child_birth_date_label"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.nafasTextPrimary)
                            
                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.nafasBackground)
                                        .overlay(RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.nafasDivider, lineWidth: 1))
                                )
                        }
                        
                        // Height and Weight with steppers
                        HStack(spacing: 12) {
                            stepperField(label: NSLocalizedString("child_height_label", comment: ""), value: $height, range: 50...200)
                            stepperField(label: NSLocalizedString("child_weight_label", comment: ""), value: $weight, range: 5...100)
                        }
                        
                        // Guardian Relationship dropdown
                        VStack(alignment: .leading, spacing: 6) {
                            Text(LocalizedStringKey("child_relationship_label"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.nafasTextPrimary)
                            
                            Menu {
                                ForEach(ChildModel.GuardianRelationship.allCases, id: \.self) { rel in
                                    Button(rel.rawValue) {
                                        relationship = rel
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(relationship.rawValue)
                                        .foregroundStyle(Color.nafasTextPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(Color.nafasTextMuted)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.nafasBackground)
                                        .overlay(RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.nafasDivider, lineWidth: 1))
                                )
                            }
                        }
                        
                        // Gender picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text(LocalizedStringKey("child_gender_label"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.nafasTextPrimary)
                            HStack(spacing: 12) {
                                ForEach(ChildModel.Gender.allCases, id: \.self) { g in
                                    Button { gender = g } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: gender == g ? "largecircle.fill.circle" : "circle")
                                                .foregroundStyle(Color.nafasPrimary)
                                            Text(g.rawValue).font(.system(size: 15)).foregroundStyle(Color.nafasTextPrimary)
                                        }
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(gender == g ? Color.nafasPrimaryLight : Color.nafasBackground)
                                                .overlay(RoundedRectangle(cornerRadius: 12)
                                                    .strokeBorder(gender == g ? Color.nafasPrimary : Color.nafasDivider, lineWidth: 1))
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Emergency Phone Numbers
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey("child_emergency_phone_label"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.nafasTextPrimary)
                            
                            ForEach(emergencyPhoneNumbers.indices, id: \.self) { idx in
                                HStack(spacing: 8) {
                                    Image(systemName: "phone.fill")
                                        .foregroundStyle(Color.nafasPrimary)
                                        .frame(width: 20)
                                    
                                    TextField(NSLocalizedString("child_emergency_phone_placeholder", comment: ""), text: $emergencyPhoneNumbers[idx])
                                        .keyboardType(.numberPad)
                                        .font(.nafasBody())
                                        .onChange(of: emergencyPhoneNumbers[idx]) { oldValue, newValue in
                                            var filtered = newValue.filter { "0123456789".contains($0) }
                                            if filtered.count > 7 {
                                                filtered = String(filtered.prefix(7))
                                            }
                                            if emergencyPhoneNumbers[idx] != filtered {
                                                emergencyPhoneNumbers[idx] = filtered
                                            }
                                        }
                                    
                                    if emergencyPhoneNumbers.count > 1 {
                                        Button {
                                            emergencyPhoneNumbers.remove(at: idx)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(Color.nafasDanger)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.nafasBackground)
                                        .overlay(RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.nafasDivider, lineWidth: 1))
                                )
                            }
                            
                            // WARNING MESSAGE
                            if !arePhonesValid {
                                Text(LocalizedStringKey("Phone numbers must be exactly 7 digits."))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.nafasDanger)
                                    .padding(.top, 2)
                            }
                            
                            if emergencyPhoneNumbers.count < 3 {
                                Button {
                                    emergencyPhoneNumbers.append("")
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle")
                                        Text(LocalizedStringKey("child_add_emergency_phone"))
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.nafasPrimary)
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                    
                    Button {
                        saveChanges()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(LocalizedStringKey("edit_child_save_button"))
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    // Validates exact 7 digits
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || !arePhonesValid || isSaving)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(!name.trimmingCharacters(in: .whitespaces).isEmpty && arePhonesValid && !isSaving ? Color.nafasPrimary : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
            .background(Color.nafasBackground.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("edit_child_nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundStyle(Color.nafasTextPrimary)
                    }
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedAvatarImage = image
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func stepperField(label: String, value: Binding<String>, range: ClosedRange<Int>) -> some View {
        let intValue = Int(value.wrappedValue) ?? 0
        
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.nafasTextPrimary)
            
            HStack {
                Button {
                    let newValue = max(range.lowerBound, intValue - 1)
                    value.wrappedValue = "\(newValue)"
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.nafasPrimary)
                }
                
                TextField("0", text: value)
                    .font(.system(size: 18, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                
                Button {
                    let newValue = min(range.upperBound, intValue + 1)
                    value.wrappedValue = "\(newValue)"
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.nafasPrimary)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.nafasBackground)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.nafasDivider, lineWidth: 1))
            )
        }
    }
    
    private func saveChanges() {
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            var updated = child
            updated.name = name.trimmingCharacters(in: .whitespaces)
            updated.birthDate = birthDate
            updated.height = Int(height)
            updated.weight = Int(weight)
            updated.gender = gender
            updated.guardianRelationship = relationship
            updated.avatarColor = selectedColor
            updated.avatarImageData = selectedAvatarImage?.jpegData(compressionQuality: 0.7)
            updated.emergencyPhoneNumbers = emergencyPhoneNumbers.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            store.updateChild(updated)
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - AddPeakFlowView

struct AddPeakFlowView: View {
    let child: ChildModel
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = NafasStore.shared
    
    @State private var peakValue = ""
    @State private var note = ""
    @State private var isSaving = false
    @State private var showSuccess = false
    
    private var intValue: Int { Int(peakValue) ?? 0 }
    private var zone: PeakZone {
        if intValue >= 240 { return .green }
        if intValue >= 160 { return .yellow }
        return intValue > 0 ? .red : .none
    }
    
    private enum PeakZone { case green, yellow, red, none }
    
    private var zoneColor: Color {
        switch zone {
        case .green:  return .nafasSuccess
        case .yellow: return .nafasWarning
        case .red:    return .nafasDanger
        case .none:   return .nafasTextMuted
        }
    }
    private var zoneLabel: String {
        switch zone {
        case .green:  return NSLocalizedString("peak_zone_green_label", comment: "")
        case .yellow: return NSLocalizedString("peak_zone_yellow_label", comment: "")
        case .red:    return NSLocalizedString("peak_zone_red_label", comment: "")
        case .none:   return NSLocalizedString("peak_zone_none_label", comment: "")
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 8)
                    
                    // Icon
                    ZStack {
                        Circle().fill(zoneColor.opacity(0.12)).frame(width: 90, height: 90)
                        Image(systemName: "lungs.fill")
                            .font(.system(size: 40)).foregroundStyle(zoneColor)
                    }
                    
                    // Value input
                    VStack(spacing: 8) {
                        Text(LocalizedStringKey("peak_flow_reading_label"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.nafasTextPrimary)
                        HStack(alignment: .lastTextBaseline, spacing: 6) {
                            TextField("000", text: $peakValue)
                                .font(.system(size: 64, weight: .bold))
                                .foregroundStyle(zoneColor)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 160)
                            Text("L/min")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.nafasTextMuted)
                        }
                        // Zone indicator
                        if intValue > 0 {
                            HStack(spacing: 6) {
                                Circle().fill(zoneColor).frame(width: 8, height: 8)
                                Text(zoneLabel)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(zoneColor)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 6)
                            .background(zoneColor.opacity(0.10), in: Capsule())
                        }
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 20))
                    
                    // Zone reference guide
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LocalizedStringKey("peak_zone_reference_label"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.nafasTextPrimary)
                        zoneGuideRow(color: .nafasSuccess, zone: NSLocalizedString("peak_zone_green", comment: ""), description: NSLocalizedString("peak_zone_green_desc", comment: ""))
                        zoneGuideRow(color: .nafasWarning, zone: NSLocalizedString("peak_zone_yellow", comment: ""), description: NSLocalizedString("peak_zone_yellow_desc", comment: ""))
                        zoneGuideRow(color: .nafasDanger,  zone: NSLocalizedString("peak_zone_red", comment: ""),    description: NSLocalizedString("peak_zone_red_desc", comment: ""))
                    }
                    .padding(16)
                    .background(Color.nafasSurface, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Optional note
                    VStack(alignment: .leading, spacing: 6) {
                        Text(LocalizedStringKey("peak_note_label"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.nafasTextPrimary)
                        TextField(NSLocalizedString("peak_note_placeholder", comment: ""), text: $note, axis: .vertical)
                            .font(.nafasBody())
                            .lineLimit(3, reservesSpace: true)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.nafasBackground)
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.nafasDivider, lineWidth: 1))
                            )
                    }
                    
                    Button {
                        saveReading()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(LocalizedStringKey("peak_save_button"))
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .disabled(intValue == 0 || isSaving)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(intValue > 0 && !isSaving ? Color.nafasPrimary : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
            .background(Color.nafasBackground.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("add_peak_flow_nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundStyle(Color.nafasTextPrimary)
                    }
                }
            }
            .alert(LocalizedStringKey("peak_reading_saved_title"), isPresented: $showSuccess) {
                Button(LocalizedStringKey("peak_reading_saved_done")) { dismiss() }
            } message: {
                Text(String(format: NSLocalizedString("peak_reading_saved_message", comment: ""), intValue, child.name))
            }
        }
    }
    
    private func zoneGuideRow(color: Color, zone: String, description: String) -> some View {
        HStack(spacing: 12) {
            Circle().fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(zone).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.nafasTextPrimary)
                Text(description).font(.system(size: 12)).foregroundStyle(Color.nafasTextMuted)
            }
        }
    }
    
    private func saveReading() {
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let now = Date()
            let df = DateFormatter()
            df.dateFormat = "EEE, d MMM"
            let tf = DateFormatter()
            tf.dateFormat = "hh:mm a"
            let entry = PeakFlowEntry(
                value: intValue,
                date: df.string(from: now),
                time: tf.string(from: now),
                note: note
            )
            store.addPeakFlow(childID: child.id.uuidString, entry: entry)
            isSaving = false
            showSuccess = true
        }
    }
}
