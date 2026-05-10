import SwiftUI
import PhotosUI

struct AddChildView: View {
    @StateObject private var viewModel = AddChildViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    
    // Temporary variables for the "Add New" form
    @State private var newContactName: String = ""
    @State private var newContactPhone: String = ""
    @AppStorage("nafas_language") private var language = "English"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Avatar preview with photo picker
                    VStack(spacing: 12) {
                        Button { showPhotoPicker = true } label: {
                            ZStack {
                                if let image = viewModel.selectedAvatarImage {
                                    Image(uiImage: image).resizable().scaledToFill().frame(width: 80, height: 80).clipShape(Circle())
                                } else {
                                    Circle().fill(Color(hex: viewModel.selectedColor)).frame(width: 80, height: 80)
                                    Text(viewModel.name.isEmpty ? "?" : String(viewModel.name.prefix(1)).uppercased())
                                        .font(.system(size: 32, weight: .bold)).foregroundStyle(.white)
                                }
                            }
                        }
                        .overlay(
                            Circle().strokeBorder(Color.white, lineWidth: 2).background(Circle().fill(Color.black.opacity(0.5))).frame(width: 28, height: 28)
                                .overlay(Image(systemName: "camera.fill").font(.system(size: 12)).foregroundStyle(.white))
                                .offset(x: 28, y: 28)
                        )
                        
                        Text(LocalizedStringKey("child_tap_to_add_photo")).font(.nafasCaption()).foregroundStyle(Color.nafasTextMuted)
                        Text(LocalizedStringKey("child_choose_color")).font(.nafasCaption()).foregroundStyle(Color.nafasTextMuted).padding(.top, 4)
                        
                        HStack(spacing: 16) {
                            ForEach(viewModel.avatarColors, id: \.self) { color in
                                Circle().fill(Color(hex: color)).frame(width: 40, height: 40)
                                    .overlay(Circle().strokeBorder(Color.white, lineWidth: viewModel.selectedColor == color ? 3 : 0).shadow(color: .black.opacity(0.15), radius: 4))
                                    .onTapGesture { viewModel.selectedColor = color }
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Form fields
                    VStack(spacing: 16) {
                        NafasTextField(labelKey: "child_full_name_label", placeholderKey: "child_full_name_placeholder", icon: "person", text: $viewModel.name)
                        
                        // Birth Date picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text(LocalizedStringKey("child_birth_date_label")).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.nafasTextPrimary)
                            DatePicker("", selection: $viewModel.birthDate, displayedComponents: .date).datePickerStyle(.compact).labelsHidden().frame(maxWidth: .infinity, alignment: .leading).padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.nafasBackground).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.nafasDivider, lineWidth: 1)))
                        }
                        
                        // Height and Weight
                        HStack(spacing: 12) {
                            stepperField(labelKey: "child_height_label", value: $viewModel.height, range: 50...200)
                            stepperField(labelKey: "child_weight_label", value: $viewModel.weight, range: 5...100)
                        }
                        
                        // Guardian Relationship
                        VStack(alignment: .leading, spacing: 6) {
                            Text(LocalizedStringKey("child_relationship_label")).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.nafasTextPrimary)
                            Menu {
                                ForEach(ChildModel.GuardianRelationship.allCases, id: \.self) { rel in
                                    Button { viewModel.relationship = rel } label: {
                                        Text(LocalizedStringKey(rel.rawValue))
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(LocalizedStringKey(viewModel.relationship.rawValue)).foregroundStyle(Color.nafasTextPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down").foregroundStyle(Color.nafasTextMuted)
                                }.padding().background(RoundedRectangle(cornerRadius: 12).fill(Color.nafasBackground).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.nafasDivider, lineWidth: 1)))
                            }
                        }
                        
                        // Gender picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text(LocalizedStringKey("child_gender_label")).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.nafasTextPrimary)
                            HStack(spacing: 12) {
                                ForEach(ChildModel.Gender.allCases, id: \.self) { g in
                                    Button { viewModel.gender = g } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: viewModel.gender == g ? "largecircle.fill.circle" : "circle").foregroundStyle(Color.nafasPrimary)
                                            Text(LocalizedStringKey(g.rawValue)).font(.system(size: 15)).foregroundStyle(Color.nafasTextPrimary)
                                        }
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(viewModel.gender == g ? Color.nafasPrimaryLight : Color.nafasBackground).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(viewModel.gender == g ? Color.nafasPrimary : Color.nafasDivider, lineWidth: 1)))
                                    }
                                }
                            }
                        }
                        
                        // MARK: - Emergency Contacts Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedStringKey("child_emergency_phone_label"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.nafasTextPrimary)
                            
                            // 1. Existing Contacts List
                            if !viewModel.emergencyContacts.isEmpty {
                                VStack(spacing: 10) {
                                    ForEach(viewModel.emergencyContacts) { contact in
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.nafasPrimary.opacity(0.10))
                                                    .frame(width: 38, height: 38)
                                                Image(systemName: "phone.fill")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundStyle(Color.nafasPrimary)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(contact.name)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundStyle(Color.nafasTextPrimary)
                                                Text(contact.phoneNumber)
                                                    .font(.system(size: 13, weight: .regular))
                                                    .foregroundStyle(Color.nafasTextMuted)
                                            }
                                            
                                            Spacer()
                                            
                                            Button {
                                                withAnimation {
                                                    viewModel.emergencyContacts.removeAll { $0.id == contact.id }
                                                }
                                            } label: {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundStyle(Color.nafasDanger)
                                                    .padding(8)
                                                    .background(Color.nafasDanger.opacity(0.1), in: Circle())
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
                                }
                            }
                            
                            // WARNING MESSAGE
                            if !viewModel.arePhonesValid {
                                Text(LocalizedStringKey("Phone numbers must be exactly 9 digits."))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.nafasDanger)
                                    .padding(.top, 2)
                            }
                            
                            // 2. Add New Contact Area
                            if viewModel.emergencyContacts.count < 3 {
                                VStack(spacing: 12) {
                                    NafasTextField(
                                            labelKey: "contact_name_label",
                                            placeholderKey: "contact_name_placeholder",
                                            icon: "person.text.rectangle",
                                            text: $newContactName
                                        )                                        .font(.system(size: 15))
                                        .padding(14)
                                        .background(Color.nafasBackground, in: RoundedRectangle(cornerRadius: 12))
                                    
                                    NafasTextField(
                                            labelKey: "child_emergency_phone",
                                            placeholderKey: "child_emergency_phone_placeholder",
                                            icon: "phone",
                                            text: $newContactPhone
                                        )                                        .font(.system(size: 15))
                                        .keyboardType(.numberPad)
                                        .padding(14)
                                        .background(Color.nafasBackground, in: RoundedRectangle(cornerRadius: 12))
                                        .onChange(of: newContactPhone) { oldValue, newValue in
                                            var filtered = newValue.filter { "0123456789".contains($0) }
                                            if filtered.count > 9 {
                                                filtered = String(filtered.prefix(9))
                                            }
                                            if newContactPhone != filtered {
                                                newContactPhone = filtered
                                            }
                                        }
                                    
                                    Button {
                                        let cleanPhone = newContactPhone.filter { "0123456789".contains($0) }
                                        let newContact = EmergencyContact(name: newContactName, phoneNumber: cleanPhone)
                                        
                                        withAnimation {
                                            viewModel.emergencyContacts.append(newContact)
                                        }
                                        
                                        // Reset fields
                                        newContactName = ""
                                        newContactPhone = ""
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus.circle")
                                            Text(LocalizedStringKey("child_add_emergency_phone"))
                                        }
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.nafasPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.nafasPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                    }
                                    .disabled(newContactName.trimmingCharacters(in: .whitespaces).isEmpty || newContactPhone.count < 9)
                                    .opacity((newContactName.trimmingCharacters(in: .whitespaces).isEmpty || newContactPhone.count < 9) ? 0.5 : 1.0)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.nafasDivider, style: StrokeStyle(lineWidth: 1, dash: [6]))
                                )
                                .padding(.top, 4)
                            }
                        }
                    }
                    
                    // Save button
                    // Save button
                    Button {
                        // 1. Auto-save any valid pending contact left in the text fields
                        if !newContactName.trimmingCharacters(in: .whitespaces).isEmpty && newContactPhone.count == 9 {
                            let cleanPhone = newContactPhone.filter { "0123456789".contains($0) }
                            let newContact = EmergencyContact(name: newContactName, phoneNumber: cleanPhone)
                            
                            // Ensure we don't exceed the 3 contact limit
                            if viewModel.emergencyContacts.count < 3 {
                                viewModel.emergencyContacts.append(newContact)
                            }
                        }
                        
                        // 2. Proceed to save the child
                        viewModel.saveChild()
                    } label: {
                        if viewModel.isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text(LocalizedStringKey("add_child_save_button"))
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(viewModel.isValid && !viewModel.isSaving ? Color.nafasPrimary : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
            .background(Color.nafasBackground.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("add_child_nav_title")).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button { dismiss() } label: { Image(systemName: "xmark").foregroundStyle(Color.nafasTextPrimary) } }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self), let image = UIImage(data: data) { await MainActor.run { viewModel.selectedAvatarImage = image } }
                }
            }
            .fullScreenCover(item: $viewModel.createdChild) { child in
                BluetoothConnectionView(child: child, isNewChild: true)
            }
            .onChange(of: viewModel.createdChild) { oldValue, newValue in
                if newValue == nil && oldValue != nil { dismiss() }
            }
        }.environment(\.layoutDirection, language == "Arabic" ? .rightToLeft : .leftToRight)
    }
    
    @ViewBuilder
    private func stepperField(labelKey: String, value: Binding<String>, range: ClosedRange<Int>) -> some View {
        let intValue = Int(value.wrappedValue) ?? 0
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(labelKey)).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.nafasTextPrimary)
            HStack {
                Button { value.wrappedValue = "\(max(range.lowerBound, intValue - 1))" } label: { Image(systemName: "minus.circle").font(.system(size: 24)).foregroundStyle(Color.nafasPrimary) }
                TextField("0", text: value).font(.system(size: 18, weight: .semibold)).multilineTextAlignment(.center).keyboardType(.numberPad).frame(width: 60)
                Button { value.wrappedValue = "\(min(range.upperBound, intValue + 1))" } label: { Image(systemName: "plus.circle").font(.system(size: 24)).foregroundStyle(Color.nafasPrimary) }
            }.padding(8).background(RoundedRectangle(cornerRadius: 12).fill(Color.nafasBackground).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.nafasDivider, lineWidth: 1)))
        }
    }
}
