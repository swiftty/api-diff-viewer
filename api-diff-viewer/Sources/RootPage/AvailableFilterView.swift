import SwiftUI

struct AvailableFilterView: View {
    @Binding var minVersion: String
    @Binding var maxVersion: String

    @State private var editingMinVersion: String = ""
    @State private var editingMaxVersion: String = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            TextField("min", text: $editingMinVersion)
            TextField("max", text: $editingMaxVersion)

            Button("Apply") {
                minVersion = editingMinVersion
                maxVersion = editingMaxVersion
                dismiss()
            }
        }
        .padding()
        .onAppear {
            editingMinVersion = minVersion
            editingMaxVersion = maxVersion
        }
    }
}

// MARK: -

#Preview {
    @Previewable @State var isPresented = true

    Button {
        isPresented.toggle()
    } label: {
        Text("Show")
    }
    .padding()
    .popover(isPresented: $isPresented) {
        AvailableFilterView(minVersion: .constant(""), maxVersion: .constant(""))
    }
}

#Preview {
    @Previewable @State var isPresented = true

    Button {
        isPresented.toggle()
    } label: {
        Text("Show")
    }
    .padding()
    .popover(isPresented: $isPresented) {
        AvailableFilterView(minVersion: .constant("26"), maxVersion: .constant(""))
    }
}
