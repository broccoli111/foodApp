import SwiftUI
import PhotosUI

struct ScanView: View {
    @EnvironmentObject private var store: KitchenStore
    @State private var pastedText = ""
    @State private var recipePreview: Recipe?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingReceiptScanner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionTitle(title: "Scan", subtitle: "Import receipts and recipes with review before saving.")

                    CompassCard {
                        HStack(spacing: 12) {
                            Button {
                                showingReceiptScanner = true
                            } label: {
                                Label("Scan receipt", systemImage: "doc.text.viewfinder")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Label("Upload", systemImage: "photo")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        Text("Receipt scans always open a confirmation sheet. Only selected and reviewed items are added to pantry.")
                            .font(.caption)
                            .foregroundStyle(Color.muted)
                    }

                    SectionTitle(title: "Recipe text", subtitle: "Paste recipe text here, or use Recipes > Add for URLs and Instagram links.")
                    TextEditor(text: $pastedText)
                        .frame(minHeight: 140)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                    Button("Extract recipe text") { recipePreview = ScanService.parseRecipe(text: pastedText, householdID: store.household.id) }
                        .buttonStyle(.bordered)

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
            .sheet(isPresented: $showingReceiptScanner) {
                ReceiptScanSheet()
                    .environmentObject(store)
            }
        }
    }
}

struct ReceiptScanIconButton: View {
    @EnvironmentObject private var store: KitchenStore
    @State private var showingReceiptScanner = false

    var body: some View {
        Button {
            showingReceiptScanner = true
        } label: {
            Image(systemName: "doc.text.viewfinder")
        }
        .accessibilityLabel("Scan receipt")
        .sheet(isPresented: $showingReceiptScanner) {
            ReceiptScanSheet()
                .environmentObject(store)
        }
    }
}

struct ReceiptScanSheet: View {
    @EnvironmentObject private var store: KitchenStore
    @Environment(\.dismiss) private var dismiss
    @State private var pastedReceiptText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var reviewItems: [ParsedReceiptItem] = []
    @State private var showingReview = false
    @State private var processingMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionTitle(title: "Scan receipt", subtitle: "Take a pass through every item before anything enters the pantry.")

                    CompassCard {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Choose receipt image", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .onChange(of: selectedPhoto) { _, newValue in
                            guard newValue != nil else { return }
                            processReceiptText("")
                        }

                        Text("Image OCR is currently mocked behind ScanService. Paste receipt text below for deterministic local testing.")
                            .font(.caption)
                            .foregroundStyle(Color.muted)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Receipt text")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.muted)
                        TextEditor(text: $pastedReceiptText)
                            .frame(minHeight: 160)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                    Button {
                        processReceiptText(pastedReceiptText)
                    } label: {
                        Label("Process receipt", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if let processingMessage {
                        Text(processingMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.muted)
                    }
                }
                .padding()
            }
            .kitchenScreen()
            .navigationTitle("Receipt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingReview) {
                ReceiptReviewSheet(items: $reviewItems) { approvedItems in
                    store.approveReceiptItems(approvedItems)
                    showingReview = false
                    dismiss()
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private func processReceiptText(_ text: String) {
        reviewItems = ScanService.parseReceipt(text: text)
        if reviewItems.isEmpty {
            processingMessage = "No receipt items found. Try pasting item lines manually."
        } else {
            let itemWord = reviewItems.count == 1 ? "item" : "items"
            processingMessage = "Found \(reviewItems.count) possible pantry \(itemWord). Review before adding."
        }
        showingReview = !reviewItems.isEmpty
    }
}

struct ReceiptReviewSheet: View {
    @Binding var items: [ParsedReceiptItem]
    let onAddSelected: ([ParsedReceiptItem]) -> Void
    @Environment(\.dismiss) private var dismiss

    private var selectedCount: Int {
        items.filter(\.approved).count
    }

    private var addButtonTitle: String {
        let itemWord = selectedCount == 1 ? "item" : "items"
        return "Add \(selectedCount) selected \(itemWord) to pantry"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Review each extracted item. Edit the name or count, and uncheck anything that should not go into pantry.")
                            .font(.footnote)
                            .foregroundStyle(Color.muted)
                            .padding(.horizontal)
                            .padding(.top)

                        ForEach($items) { $item in
                            ReceiptReviewItemRow(item: $item)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 16)
                }

                VStack(spacing: 10) {
                    Button {
                        onAddSelected(items.filter(\.approved))
                    } label: {
                        Text(addButtonTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedCount == 0)

                    Button("Cancel", role: .cancel) { dismiss() }
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(.regularMaterial)
            }
            .navigationTitle("Confirm receipt items")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ReceiptReviewItemRow: View {
    @Binding var item: ParsedReceiptItem

    var body: some View {
        CompassCard {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    item.approved.toggle()
                } label: {
                    Image(systemName: item.approved ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundStyle(item.approved ? Color.basil : Color.muted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.approved ? "Deselect item" : "Select item")

                VStack(alignment: .leading, spacing: 10) {
                    TextField("Item name", text: $item.name)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 10) {
                        TextField("Count", value: $item.quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 110)

                        Text(item.unit)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.muted)

                        Spacer()

                        Text("\(Int(item.confidence * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.muted)
                    }

                    Text("From: \(item.rawText)")
                        .font(.caption)
                        .foregroundStyle(Color.muted)
                        .lineLimit(2)
                }
            }
        }
    }
}
