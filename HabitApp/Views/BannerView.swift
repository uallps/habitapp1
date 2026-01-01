import SwiftUI

struct BannerView: View {
    var title: String
    var message: String

    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bell.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()
            }
            .padding()
            .background(Color.cyan)
            .cornerRadius(16)
            .shadow(radius: 6)
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()
        }
    }
}
