import SwiftUI

struct CompromiseRow: View {
    let icon: String, title: String, desc: String
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon).font(.title2).frame(width: 30).foregroundStyle(.blue)
            VStack(alignment: .leading) {
                Text(title).bold()
                Text(desc).font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
