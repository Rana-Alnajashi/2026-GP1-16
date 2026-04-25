import SwiftUI
import PhotosUI

struct EditChildView: View{
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
        return activePhones.allSatisfy { $0.count == 9 }
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
