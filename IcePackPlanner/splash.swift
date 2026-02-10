
import SwiftUI
import Combine

#Preview {
    LightDepthNotesSplashScreen()
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct UnavailableView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("screen_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                
                Image("alert_internet")
                    .resizable()
                    .frame(width: 300, height: 270)
            }
        }
        .ignoresSafeArea()
    }
}

struct LightDepthNotesSplashScreen: View {
    @State private var animateLogo = false
    @State private var animateText = false
    @State private var animateParticles = false
    @State private var showLoader = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    @State private var waveOffset1: CGFloat = 0
    @State private var waveOffset2: CGFloat = 0
    @State private var waveOffset3: CGFloat = 0
    @State private var inkDrop1 = false
    @State private var inkDrop2 = false
    @StateObject private var flux = FluxContainer()
    @State private var streams = Set<AnyCancellable>()
    @State private var inkDrop3 = false
    
    var body: some View {
        ZStack {
            if flux.navigateToWeb {
                PackWebView()
            } else if flux.navigateToMain {
                RootView()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: "F8F9FA"),
                            Color(hex: "E9ECEF"),
                            Color(hex: "DEE2E6"),
                            Color(hex: "F8F9FA")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    LightWaveLayer(offset: waveOffset1, opacity: 0.05, speed: 3.0)
                    LightWaveLayer(offset: waveOffset2, opacity: 0.08, speed: 4.0)
                    LightWaveLayer(offset: waveOffset3, opacity: 0.12, speed: 5.0)
                    
                    ZStack {
                        InkDropEffect(animate: $inkDrop1, delay: 0.5, size: 300, color: Color(hex: "6C757D").opacity(0.1))
                        InkDropEffect(animate: $inkDrop2, delay: 1.2, size: 250, color: Color(hex: "495057").opacity(0.08))
                        InkDropEffect(animate: $inkDrop3, delay: 1.8, size: 200, color: Color(hex: "ADB5BD").opacity(0.06))
                    }
                    
                    if animateParticles {
                        ForEach(0..<25, id: \.self) { index in
                            FloatingPaperParticle(index: index)
                        }
                    }
                    
                    VStack(spacing: 0) {
                        Spacer()
                        
                        mainContent
                        
                        Spacer()
                        
                        loaderSection
                            .padding(.bottom, 80)
                    }
                    
                }
                .onAppear {
                    startAnimations()
                    
                    flux.actions.startApp()
                    setupStreams()
                }
            }
        }
        .fullScreenCover(isPresented: $flux.showNotificationModal) {
            PackNotificationView(flux: flux)
        }
        .fullScreenCover(isPresented: $flux.showOfflineModal) {
            UnavailableView()
        }
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { flux.actions.receiveMarketing($0) }
            .store(in: &streams)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { flux.actions.receiveRouting($0) }
            .store(in: &streams)
    }
    
    var mainContent: some View {
        VStack(spacing: 45) {
            logoSection
            
            // App title
            titleSection
        }
    }
    
    var logoSection: some View {
        ZStack {
            // Outer elegant rings with gradient
            ForEach(0..<3) { ring in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "495057").opacity(0.3),
                                Color(hex: "6C757D").opacity(0.1),
                                Color(hex: "ADB5BD").opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: 170 + CGFloat(ring * 35), height: 170 + CGFloat(ring * 35))
                    .scaleEffect(animateLogo ? 1.25 : 0.75)
                    .opacity(animateLogo ? 0 : 0.7)
                    .animation(
                        Animation.easeOut(duration: 2.2)
                            .delay(Double(ring) * 0.18)
                            .repeatForever(autoreverses: false),
                        value: animateLogo
                    )
            }
            
            // Subtle glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "6C757D").opacity(0.15),
                            Color(hex: "ADB5BD").opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .blur(radius: 25)
                .scaleEffect(pulseScale)
            
            // Main logo container with paper texture
            ZStack {
                // Paper-like background with shadow
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(hex: "F8F9FA")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 190, height: 190)
                    .shadow(color: Color(hex: "495057").opacity(0.15), radius: 30, x: 0, y: 15)
                    .shadow(color: Color(hex: "6C757D").opacity(0.08), radius: 50, x: 0, y: 25)
                
                // Border with elegant gradient
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "495057").opacity(0.4),
                                Color(hex: "6C757D").opacity(0.25),
                                Color(hex: "ADB5BD").opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 190, height: 190)
                
                // Inner subtle circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "E9ECEF").opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 85
                        )
                    )
                    .frame(width: 150, height: 150)
                
                // Document icon with pen - representing depth notes
                ZStack {
                    // Main document
                    VStack(spacing: 0) {
                        // Document with fold
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "495057"),
                                            Color(hex: "6C757D")
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 65, height: 85)
                            
                            // Paper fold corner
                            Path { path in
                                path.move(to: CGPoint(x: 65, y: 0))
                                path.addLine(to: CGPoint(x: 65, y: 20))
                                path.addLine(to: CGPoint(x: 45, y: 0))
                                path.closeSubpath()
                            }
                            .fill(Color(hex: "343A40"))
                        }
                        .overlay(
                            // Lines on document
                            VStack(spacing: 6) {
                                ForEach(0..<4) { _ in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.white.opacity(0.7))
                                        .frame(width: 45, height: 2)
                                }
                            }
                            .offset(y: 5)
                        )
                        .shadow(color: Color(hex: "212529").opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    
                    // Elegant pen on top
                    Image(systemName: "pencil.tip")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "212529"),
                                    Color(hex: "495057")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(-45))
                        .offset(x: 25, y: -15)
                        .shadow(color: Color(hex: "495057").opacity(0.3), radius: 8, x: 2, y: 4)
                }
                .rotationEffect(.degrees(rotationAngle))
            }
            .scaleEffect(animateLogo ? 1 : 0.4)
            .opacity(animateLogo ? 1 : 0)
        }
    }
    
    var titleSection: some View {
        VStack(spacing: 22) {
            // Main title with elegant shadow
            ZStack {
                // Multiple shadow layers for depth
                ForEach(0..<3) { index in
                    Text("Master Pack Planner")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "6C757D").opacity(0.15))
                        .blur(radius: CGFloat(3 + index * 2))
                        .offset(y: CGFloat(2 + index * 2))
                }
                
                // Main text with sophisticated gradient
                Text("Master Pack Planner")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "212529"),
                                Color(hex: "495057"),
                                Color(hex: "6C757D"),
                                Color(hex: "495057"),
                                Color(hex: "212529")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        // Elegant shimmer effect
                        GeometryReader { geometry in
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.6),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 100)
                            .offset(x: animateText ? geometry.size.width + 100 : -100)
                        }
                        .mask(
                            Text("DEPTH NOTES")
                                .font(.system(size: 46, weight: .heavy, design: .rounded))
                        )
                    )
            }
            .tracking(3.5)
            
            // Decorative line divider
            HStack(spacing: 16) {
                DecorativeLine()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color(hex: "6C757D").opacity(0.5),
                                Color(hex: "495057").opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 50, height: 12)
                    .opacity(animateText ? 1 : 0)
                
                // Elegant icon
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "495057"))
                    .opacity(animateText ? 1 : 0)
                
                DecorativeLine()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "495057").opacity(0.6),
                                Color(hex: "6C757D").opacity(0.5),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 50, height: 12)
                    .opacity(animateText ? 1 : 0)
            }
            
            // Subtitle with elegant typography
            Text("Where Thoughts Gain")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "6C757D"),
                            Color(hex: "495057")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .tracking(2.5)
                .opacity(animateText ? 1 : 0)
                .offset(y: animateText ? 0 : 15)
        }
    }
    
    // MARK: - Loader Section
    var loaderSection: some View {
        VStack(spacing: 22) {
            // Elegant infinite loader
            ElegantInfiniteLoader()
                .frame(width: 70, height: 70)
                .opacity(showLoader ? 1 : 0)
            
            // Loading text with animated dots
            HStack(spacing: 5) {
                Text("Preparing your workspace")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "6C757D"))
                
                HStack(spacing: 3) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color(hex: "495057"))
                            .frame(width: 4, height: 4)
                            .scaleEffect(animateDot(index: index) ? 1.3 : 0.7)
                            .opacity(animateDot(index: index) ? 1 : 0.4)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: showLoader
                            )
                    }
                }
            }
            .opacity(showLoader ? 1 : 0)
        }
    }
    
    // MARK: - Animation Functions
    func startAnimations() {
        // Wave animations
        withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) {
            waveOffset1 = UIScreen.main.bounds.width
        }
        
        withAnimation(.linear(duration: 4.5).repeatForever(autoreverses: false)) {
            waveOffset2 = UIScreen.main.bounds.width
        }
        
        withAnimation(.linear(duration: 5.5).repeatForever(autoreverses: false)) {
            waveOffset3 = UIScreen.main.bounds.width
        }
        
        // Ink drops
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            inkDrop1 = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            inkDrop2 = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            inkDrop3 = true
        }
        
        // Logo animation
        withAnimation(.spring(response: 1.3, dampingFraction: 0.65)) {
            animateLogo = true
        }
        
        // Pulse animation
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
        
        // Gentle rotation
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // Particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animateParticles = true
        }
        
        // Text animations
        withAnimation(.easeOut(duration: 0.9).delay(0.7)) {
            animateText = true
        }
        
        // Text shimmer
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false).delay(1.2)) {
            animateText = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeIn(duration: 0.5)) {
                showLoader = true
            }
        }
    }
    
    func animateDot(index: Int) -> Bool {
        return showLoader
    }
}

struct ElegantInfiniteLoader: View {
    @State private var rotation1: Double = 0
    @State private var rotation2: Double = 0
    @State private var rotation3: Double = 0
    @State private var scale1: CGFloat = 1.0
    @State private var scale2: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Outer ring with elegant gradient
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(hex: "212529"),
                            Color(hex: "495057"),
                            Color(hex: "6C757D"),
                            Color(hex: "ADB5BD"),
                            Color(hex: "212529")
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .frame(width: 70, height: 70)
                .rotationEffect(.degrees(rotation1))
                .scaleEffect(scale1)
            
            // Middle ring
            Circle()
                .trim(from: 0, to: 0.6)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(hex: "6C757D"),
                            Color(hex: "495057"),
                            Color(hex: "212529"),
                            Color(hex: "495057"),
                            Color(hex: "6C757D")
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 48, height: 48)
                .rotationEffect(.degrees(rotation2))
            
            // Inner ring
            Circle()
                .trim(from: 0, to: 0.4)
                .stroke(
                    Color(hex: "495057"),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: 26, height: 26)
                .rotationEffect(.degrees(rotation3))
                .scaleEffect(scale2)
            
            // Center dot
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "212529"),
                            Color(hex: "495057")
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 4
                    )
                )
                .frame(width: 8, height: 8)
        }
        .shadow(color: Color(hex: "495057").opacity(0.2), radius: 15, x: 0, y: 8)
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation1 = 360
            }
            
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation2 = -360
            }
            
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation3 = 360
            }
            
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                scale1 = 1.08
            }
            
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(0.3)) {
                scale2 = 1.15
            }
        }
    }
}

struct LightWaveLayer: View {
    let offset: CGFloat
    let opacity: Double
    let speed: Double
    
    var body: some View {
        WaveShape(offset: offset, percent: 0.75)
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: "6C757D").opacity(opacity),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea()
            .blur(radius: 8)
    }
}

struct WaveShape: Shape {
    var offset: CGFloat
    var percent: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waveHeight: CGFloat = 0.03 * rect.height
        let yOffset = (1 - percent) * rect.height
        
        path.move(to: CGPoint(x: 0, y: yOffset))
        
        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / 50
            let sine = sin(relativeX + offset / 50)
            let y = yOffset + waveHeight * sine
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

struct InkDropEffect: View {
    @Binding var animate: Bool
    let delay: Double
    let size: CGFloat
    let color: Color
    
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color,
                        color.opacity(0.5),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(opacity)
            .blur(radius: 10)
            .onChange(of: animate) { newValue in
                if newValue {
                    withAnimation(.easeOut(duration: 2.5)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                    
                    withAnimation(.easeOut(duration: 1.5).delay(2.5)) {
                        opacity = 0
                    }
                }
            }
    }
}

// MARK: - Floating Paper Particle
struct FloatingPaperParticle: View {
    let index: Int
    @State private var yOffset: CGFloat = UIScreen.main.bounds.height + 100
    @State private var xOffset: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    private let randomDelay: Double
    private let randomDuration: Double
    private let randomX: CGFloat
    private let randomSize: CGFloat
    private let randomRotation: Double
    
    init(index: Int) {
        self.index = index
        self.randomDelay = Double.random(in: 0...3)
        self.randomDuration = Double.random(in: 8...15)
        self.randomX = CGFloat.random(in: 0...UIScreen.main.bounds.width)
        self.randomSize = CGFloat.random(in: 8...20)
        self.randomRotation = Double.random(in: 0...360)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: randomSize / 4)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.8),
                        Color(hex: "F8F9FA").opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: randomSize, height: randomSize * 1.4)
            .overlay(
                RoundedRectangle(cornerRadius: randomSize / 4)
                    .stroke(Color(hex: "6C757D").opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color(hex: "495057").opacity(0.1), radius: 8, x: 0, y: 4)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .offset(x: xOffset, y: yOffset)
            .opacity(opacity)
            .blur(radius: 0.5)
            .onAppear {
                xOffset = randomX
                
                // Float up
                withAnimation(
                    Animation.linear(duration: randomDuration)
                        .delay(randomDelay)
                        .repeatForever(autoreverses: false)
                ) {
                    yOffset = -100
                }
                
                // Rotation
                withAnimation(
                    Animation.linear(duration: randomDuration / 2)
                        .delay(randomDelay)
                        .repeatForever(autoreverses: false)
                ) {
                    rotation = randomRotation + 360
                }
                
                // Horizontal drift
                withAnimation(
                    Animation.easeInOut(duration: randomDuration / 3)
                        .delay(randomDelay)
                        .repeatForever(autoreverses: true)
                ) {
                    xOffset = randomX + CGFloat.random(in: -40...40)
                }
                
                // Scale
                withAnimation(
                    Animation.easeInOut(duration: 2.5)
                        .delay(randomDelay)
                        .repeatForever(autoreverses: true)
                ) {
                    scale = 1.2
                }
                
                // Fade in
                withAnimation(.easeIn(duration: 1.2).delay(randomDelay)) {
                    opacity = 0.6
                }
                
                // Fade out
                withAnimation(.easeOut(duration: 2).delay(randomDelay + randomDuration - 2)) {
                    opacity = 0
                }
            }
    }
}

struct DecorativeLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / 8
            let sine = sin(relativeX) * (height / 3)
            path.addLine(to: CGPoint(x: x, y: midHeight + sine))
        }
        
        return path
    }
}

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
