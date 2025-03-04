//
//  WelcomeView.swift
//  GoMotoApp
//
//  Created by antonio garcia on 1/12/25.
//

import SwiftUI

struct WelcomeView: View {
    @Binding var isLoggedIn: Bool
    @State private var logoScale: CGFloat = 1.0
    @State private var logoRotation: Double = 0.0
    @State private var logoColor: Color = .blue

    var body: some View {
        NavigationStack {
            if isLoggedIn {
                // ✅ Show the MainTabView when logged in
                MainTabView(isLoggedIn: $isLoggedIn)
                    .transition(.slide) // Smooth transition effect
            } else {
                VStack(spacing: 30) {
                    // Animated Logo Section
                    VStack(spacing: 15) {
                        Image(systemName: "circle.grid.cross.fill") // Replace with your logo
                            .resizable()
                            .frame(width: 120, height: 120)
                            .foregroundColor(logoColor)
                            .scaleEffect(logoScale)
                            .rotationEffect(.degrees(logoRotation))
                            .onAppear {
                                withAnimation(
                                    Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
                                ) {
                                    logoScale = 1.1
                                }
                                withAnimation(
                                    Animation.linear(duration: 6).repeatForever(autoreverses: false)
                                ) {
                                    logoRotation = 360
                                }
                                withAnimation(
                                    Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)
                                ) {
                                    logoColor = .green
                                }
                            }

                        Text("Welcome to GoMoto")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .transition(.opacity)

                        Text("Connecting drivers and passengers effortlessly.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 30)
                    }

                    Spacer()

                    // Navigation Buttons
                    VStack(spacing: 15) {
                        NavigationLink(destination: SignUpView(isLoggedIn: $isLoggedIn)) {
                            Text("Sign Up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(AnimatedButtonStyle())

                        NavigationLink(destination: LoginView(isLoggedIn: $isLoggedIn)) {
                            Text("Log In")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: .green.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(AnimatedButtonStyle())
                    }

                    Button(action: {
                        print("Forgot Password tapped")
                    }) {
                        Text("Forgot Password?")
                            .font(.footnote)
                            .foregroundColor(.blue)
                            .padding(.top, 10)
                    }

                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.1)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
}

// MARK: - Animated Button Style
struct AnimatedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: configuration.isPressed)
    }
}

// wecomeView for ride App bellow
/*import SwiftUI

struct WelcomeView: View {
    @Binding var isLoggedIn: Bool
    @State private var logoScale: CGFloat = 1.0
    @State private var logoRotation: Double = 0.0
    @State private var logoColor: Color = .blue

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Animated Logo Section
                VStack(spacing: 15) {
                    Image(systemName: "circle.grid.cross.fill") // Replace with your logo
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(logoColor)
                        .scaleEffect(logoScale)
                        .rotationEffect(.degrees(logoRotation))
                        .onAppear {
                            withAnimation(
                                Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
                            ) {
                                logoScale = 1.1
                            }
                            withAnimation(
                                Animation.linear(duration: 6).repeatForever(autoreverses: false)
                            ) {
                                logoRotation = 360
                            }
                            withAnimation(
                                Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)
                            ) {
                                logoColor = .green
                            }
                        }

                    Text("Welcome to GoMoto")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .transition(.opacity)

                    Text("Connecting drivers and passengers effortlessly.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 30)
                }

                Spacer()

                // Navigation Buttons
                VStack(spacing: 15) {
                    NavigationLink(destination: SignUpView(isLoggedIn: $isLoggedIn)) {
                        Text("Sign Up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(AnimatedButtonStyle())

                    NavigationLink(destination: LoginView(isLoggedIn: $isLoggedIn)) {
                        Text("Log In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .green.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(AnimatedButtonStyle())
                }

                Button(action: {
                    print("Forgot Password tapped")
                }) {
                    Text("Forgot Password?")
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .padding(.top, 10)
                }

                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

// MARK: - Animated Button Style
struct AnimatedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: configuration.isPressed)
    }
}*/



