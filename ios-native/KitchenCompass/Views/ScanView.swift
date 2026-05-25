import SwiftUI
import PhotosUI

struct ScanView: View {
    @EnvironmentObject private var store: KitchenStore
    @State private var pastedText = ""
    @State private var receiptItems: [ParsedReceiptItem] = []
    @State private var recipePreview: Recipe?
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionTitle(title: "Scan", subtitle: "Native image picking with mocked OCR/parsing hooks.")
                    CompassCard {
                        PhotosPicker("Upload image", selection: $selectedPhoto, matching: .images)
                            .buttonStyle(.borderedProminent)
                        Text("Image selection is wired for native iOS. OCR is mocked behind ScanService so Vision or a backend parser can replace it.")
                            .font(.caption)
                            .foregroundStyle(Color.muted)
                    }

                    TextEditor(text: $pastedText)
                        .frame(minHeight: 140)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                    HStack {
                        Button("Extract receipt") { receiptItems = ScanService.parseReceipt(text: pastedText) }
                            .buttonStyle(.borderedProminent)
                        Button("Extract recipe") { recipePreview = ScanService.parseRecipe(text: pastedText, householdID: store.household.id) }
                            .buttonStyle(.bordered)
                    }

                    if !receiptItems.isEmpty {
                        SectionTitle(title: "Receipt review")
                        ForEach($receiptItems) { $item in
                            CompassCard {
                                Toggle(isOn: $item.approved) {
                                    VStack(alignment: .leading) {
                                        Text(item.name).font(.headline)
                                        Text("From \(item.rawText) - \(Int(item.confidence * 100))% confidence")
                                            .font(.caption)
                                            .foregroundStyle(Color.muted)
                                    }
                                }
                            }
                        }
                        Button("Add approved to pantry") { store.approveReceiptItems(receiptItems); receiptItems = [] }
                            .buttonStyle(.borderedProminent)
                    }

                    if let recipePreview {
                        SectionTitle(title: "Recipe review")
                        CompassCard {
                            Text(recipePreview.title).font(.headline)
                            ForEach(recipePreview.ingredients) { ingredient in
                                Text(ingredient.rawText).foregroundStyle(Color.muted)
                            }
                            Button("Save recipe") { store.addRecipe(recipePreview); self.recipePreview = nil }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .padding()
            }
            .kitchenScreen()
            .navigationTitle("Scan")
        }
    }
}
