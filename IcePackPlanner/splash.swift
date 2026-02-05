
import SwiftUI

// MARK: - Splash Screen
struct SplashView: View {
    @EnvironmentObject var appState: AppState
    @State private var isAnimating = false
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            VStack(spacing: 20) {
                ZStack {
                    Image(systemName: "bag")
                        .font(.system(size: 80, weight: .thin))
                        .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.6))
                    
                    Image(systemName: "snowflake")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundColor(.cyan)
                        .offset(x: 30, y: -30)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.95)
                
                Text("Ice Pack Planner")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.6))
            }
            .opacity(isAnimating ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                isAnimating = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
}

// MARK: - Onboarding
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            VStack {
                TabView(selection: $currentPage) {
                    OnboardingPage1().tag(0)
                    OnboardingPage2().tag(1)
                    OnboardingPage3().tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                
                HStack(spacing: 20) {
                    if currentPage < 2 {
                        Button("Skip") {
                            appState.completeOnboarding()
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(currentPage == 2 ? "Get Started" : "Continue") {
                        if currentPage < 2 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            appState.completeOnboarding()
                        }
                    }
                    .foregroundColor(.cyan)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage1: View {
    @State private var showItems = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checklist")
                .font(.system(size: 80, weight: .thin))
                .foregroundColor(.cyan)
            
            Text("Prepare everything\nbefore the trip")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.6))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                ForEach(0..<3) { index in
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.cyan)
                        Text("Item \(index + 1)")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .opacity(showItems ? 1 : 0)
                    .animation(.easeIn.delay(Double(index) * 0.2), value: showItems)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .onAppear {
            showItems = true
        }
    }
}

struct OnboardingPage2: View {
    @State private var bounce = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "bag.fill")
                .font(.system(size: 80, weight: .thin))
                .foregroundColor(.cyan)
                .scaleEffect(bounce ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: bounce)
            
            Text("Use ready-made\ngear packs")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.6))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .onAppear {
            bounce = true
        }
    }
}

struct OnboardingPage3: View {
    @State private var showCheck = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.cyan, lineWidth: 3)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .thin))
                    .foregroundColor(.cyan)
                    .scaleEffect(showCheck ? 1.0 : 0.0)
            }
            
            Text("Never forget\nimportant gear")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.6))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showCheck = true
            }
        }
    }
}
