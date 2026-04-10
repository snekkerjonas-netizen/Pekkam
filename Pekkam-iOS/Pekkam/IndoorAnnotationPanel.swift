import SwiftUI

struct IndoorAnnotationPanel: View {
    @Binding var floor: Int?
    @Binding var room: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Innvendig lokalisering")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            VStack(spacing: 12) {
                Text("Etasje")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 16) {
                    Button(action: { if let f = floor { floor = f - 1 } }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }
                    
                    Text(String(floor ?? 0))
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                    
                    Button(action: { floor = (floor ?? 0) + 1 }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            VStack(spacing: 8) {
                Text("Rom")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("Rom navn", text: $room)
                    .textFieldStyle(.roundedBorder)
                    .padding(.vertical, 8)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Lagre")
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .glassPanel()
    }
}
