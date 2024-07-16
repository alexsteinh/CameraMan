import SwiftUI

struct ContentView: View {
    var body: some View {
        CameraView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .statusBar(hidden: true)
    }
}

#Preview {
    ContentView()
}
