import SwiftUI
import PhotosUI

struct AddChildView: View {
    @StateObject private var viewModel = AddChildViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    
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
                            // 🚀 FIX 1: Passing the exact localization keys
                            stepperField(labelKey: "child_height_label", value: $viewModel.height, range: 50...200)
                            stepperField(labelKey: "child_weight_label", value: $viewModel.weight, range: 5...100)
                        }
                        
                        // Guardian Relationship
                        VStack(alignment: .leading, spacing: 6) {
                            Text(LocalizedStringKey("child_relationship_label")).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.nafasTextPrimary)
                            Menu {
                                ForEach(ChildModel.GuardianRelationship.allCases, id: \.self) { rel in
                                    // 🚀 FIX 2: Wrapped Relatives in LocalizedStringKey
                                    Button { viewModel.relationship = rel } label: {
                                        Text(LocalizedStringKey(rel.rawValue))
                                    }
                                }
                            } label: {
                                HStack {
                                    // 🚀 FIX 2: Wrapped the selected state in LocalizedStringKey
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
                                            // 🚀 Wrapped Gender in LocalizedStringKey as well
                                            Text(LocalizedStringKey(g.rawValue)).font(.system(size: 15)).foregroundStyle(Color.nafasTextPrimary)
                                        }
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(viewModel.gender == g ? Color.nafasPrimaryLight : Color.nafasBackground).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(viewModel.gender == g ? Color.nafasPrimary : Color.nafasDivider, lineWidth: 1)))
                                    }
                                }
                            }
                        }
                        
                        // Emergency Phone Numbers
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey("child_emergency_phone_label")).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.nafasTextPrimary)
                            
                            ForEach(viewModel.emergencyPhoneNumbers.indices, id: \.self) { idx in
                                HStack(spacing: 8) {
                                    Image(systemName: "phone.fill").foregroundStyle(Color.nafasPrimary).frame(width: 20)
                                    TextField(NSLocalizedString("child_emergency_phone_placeholder", comment: ""), text: $viewModel.emergencyPhoneNumbers[idx])
                                        .keyboardType(.numberPad).font(.nafasBody())
                                        .onChange(of: viewModel.emergencyPhoneNumbers[idx]) { oldValue, newValue in
                                            var filtered = newValue.filter { "0123456789".contains($0) }
                                            if filtered.count > 9 { filtered = String(filtered.prefix(9)) }
                                            if viewModel.emergencyPhoneNumbers[idx] != filtered { viewModel.emergencyPhoneNumbers[idx] = filtered }
                                        }
                                    if viewModel.emergencyPhoneNumbers.count > 1 {
                                        Button { viewModel.emergencyPhoneNumbers.remove(at: idx) } label: { Image(systemName: "minus.circle.fill").foregroundStyle(Color.nafasDanger) }
                                    }
                                }
                                .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.nafasBackground).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.nafasDivider, lineWidth: 1)))
                            }
                            
                            if !viewModel.arePhonesValid {
                                Text(LocalizedStringKey("Phone numbers must be exactly 9 digits.")).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.nafasDanger).padding(.top, 2)
                            }
                            
                            if viewModel.emergencyPhoneNumbers.count < 3 {
                                Button { viewModel.emergencyPhoneNumbers.append("") } label: {
                                    HStack(spacing: 6) { Image(systemName: "plus.circle"); Text(LocalizedStringKey("child_add_emergency_phone")) }.font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.nafasPrimary).padding(.top, 4)
                                }
                            }
                        }
                    }
                    
                    // Save button
                    Button {
                        viewModel.saveChild()
                    } label: {
                        if viewModel.isSaving { ProgressView().tint(.white) } else { Text(LocalizedStringKey("add_child_save_button")).font(.system(size: 16, weight: .bold)) }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(viewModel.isValid && !viewModel.isSaving ? Color.nafasPrimary : Color.gray).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16)).padding(.bottom, 20)
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
        }
    }
    
    @ViewBuilder
    // 🚀 FIX 1: Accepting labelKey instead of label
    private func stepperField(labelKey: String, value: Binding<String>, range: ClosedRange<Int>) -> some View {
        let intValue = Int(value.wrappedValue) ?? 0
        VStack(alignment: .leading, spacing: 6) {
            // 🚀 FIX 1: Translating the key here
            Text(LocalizedStringKey(labelKey)).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.nafasTextPrimary)
            HStack {
                Button { value.wrappedValue = "\(max(range.lowerBound, intValue - 1))" } label: { Image(systemName: "minus.circle").font(.system(size: 24)).foregroundStyle(Color.nafasPrimary) }
                TextField("0", text: value).font(.system(size: 18, weight: .semibold)).multilineTextAlignment(.center).keyboardType(.numberPad).frame(width: 60)
                Button { value.wrappedValue = "\(min(range.upperBound, intValue + 1))" } label: { Image(systemName: "plus.circle").font(.system(size: 24)).foregroundStyle(Color.nafasPrimary) }
            }.padding(8).background(RoundedRectangle(cornerRadius: 12).fill(Color.nafasBackground).overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.nafasDivider, lineWidth: 1)))
        }
    }
}
