import SwiftUI

struct LabeledValue: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).monospacedDigit()
        }
    }
}
