import SwiftUI

struct ContentView: View {
    @State private var showButtons = false

    var body: some View {
        VStack {
            if showButtons {
                HStack {
                    Button("Button 1") { }
                    Button("Button 2") { }
                    Button("Button 3") { }
                }
                .transition(.buttonCluster)
            }

            Button("Toggle Buttons") {
                withAnimation {
                    showButtons.toggle()
                }
               
                            Button(action: {
                                print("Button tapped")
                            }) {
                                Text("Tap Me")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(BouncyButtonStyle())
                        
                    
                

                struct BouncyButtonStyle: ButtonStyle {
                    func makeBody(configuration: Configuration) -> some View {
                        configuration.label
                            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
                            .animation(.spring(), value: configuration.isPressed)
                    }
                }
            }
        }
    }
}
