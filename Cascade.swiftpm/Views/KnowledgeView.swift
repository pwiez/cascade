import SwiftUI
import Charts

struct KesslerDeepDiveView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.dynamicTypeSize) var typeSize
    @State private var isDarkMode = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView(isDarkMode: isDarkMode)
                    .accessibilityHidden(true)
                
                ScrollView {
                    VStack(spacing: 60) {
                        
                        HeroSection()
                        
                        VStack(spacing: 80) {
                            
                            EditorialSection(title: "The Phenomenon", subtitle: "01 / Concept") {
                                AdaptiveStack {
                                    ProseText("The Kessler Syndrome is a theoretical scenario in which the density of objects in Low Earth Orbit (LEO) becomes so high that collisions between objects cause a cascade.")
                                    ProseText("One collision creates debris. That debris destroys other satellites. The result is a planetary debris belt that could render space exploration impossible for generations.")
                                } visual: {
                                    GlassCard { LoopDiagram() }
                                        .accessibilityElement(children: .ignore)
                                        .accessibilityLabel("Diagram of the feedback loop: An impact creates debris, which increases orbital density, leading to more impacts.")
                                }
                            }
                            
                            EditorialSection(title: "Orbital Energy", subtitle: "02 / Mechanics") {
                                AdaptiveStack {
                                    ProseText("In orbit, speed is the only thing keeping objects from falling. At **17,500 mph** (7.8 km/s), even a paint fleck hits with the force of a 550lb anvil.")
                                    ProseText("There are no minor accidents in space. Kinetic energy scales with the square of velocity ($v^2$), meaning a small increase in speed creates a massive increase in destructive power.")
                                } visual: {
                                    GlassCard { ImpactComparator() }
                                }
                            }
                            
                            EditorialSection(title: "Critical Events", subtitle: "03 / History") {
                                TimelineView()
                            }
                            
                            EditorialSection(title: "Debris Density", subtitle: "04 / Status") {
                                AdaptiveStack {
                                    ProseText("We currently track over **27,000** pieces of debris larger than a softball. However, models estimate there are **100 million** pieces larger than 1mm that are untrackable.")
                                    ProseText("The 800km polar orbit—critical for climate science—is currently the most congested region in space.")
                                } visual: {
                                    GlassCard { DebrisGrowthChart() }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 30) {
                                SectionHeader(title: "Remediation", subtitle: "05 / Solutions")
                                RemediationGrid()
                            }
                        }
                        .frame(maxWidth: 900)
                        .padding(.horizontal, sizeClass == .regular ? 40 : 24)
                        
                        VStack(spacing: 8) {
                            Text("ESA Space Debris Office • NASA ODPO")
                            Text("Last Updated: Feb 2026")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 40)
                        .accessibilityElement(children: .combine)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ThemeToggle(isDarkMode: $isDarkMode)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

struct AdaptiveStack<Content: View, Visual: View>: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.dynamicTypeSize) var typeSize
    
    @ViewBuilder let content: Content
    @ViewBuilder let visual: Visual
    
    var isAccessibilitySize: Bool { typeSize > .xxxLarge }
    
    var body: some View {
        if sizeClass == .regular && !isAccessibilitySize {
            HStack(alignment: .top, spacing: 50) {
                VStack(alignment: .leading, spacing: 24) { content }
                visual.frame(width: 350)
            }
        } else {
            VStack(alignment: .leading, spacing: 30) {
                content
                visual
            }
        }
    }
}

struct HeroSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Circle().fill(Color.red).frame(width: 12, height: 12)
                Text("CRITICAL SCENARIO")
                    .font(.caption).fontWeight(.bold).tracking(2).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Status: Critical Scenario")
            
            Text("Kessler\nSyndrome")
                .font(.system(size: 64, weight: .black, design: .serif))
                .font(.largeTitle)
                .foregroundStyle(.primary)
                .lineSpacing(0)
                .accessibilityAddTraits(.isHeader)
            
            Text("A chain reaction where every collision creates shrapnel that causes more collisions, until Low Earth Orbit becomes an unusable minefield.")
                .font(.title3).foregroundStyle(.secondary).lineSpacing(6)
                .frame(maxWidth: 600, alignment: .leading)
            
            Divider().padding(.top, 20)
        }
        .padding(.top, 40)
        .padding(.horizontal, 24)
        .frame(maxWidth: 948)
    }
}

struct EditorialSection<Content: View>: View {
    let title: String, subtitle: String
    let content: Content
    
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            SectionHeader(title: title, subtitle: subtitle)
            content
        }
    }
}

struct SectionHeader: View {
    let title: String, subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(subtitle.uppercased())
                .font(.caption).fontWeight(.bold).foregroundStyle(.blue).tracking(1)
                .accessibilityLabel("Section \(subtitle)")
            Text(title)
                .font(.largeTitle).fontWeight(.bold).fontDesign(.serif).foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

struct ProseText: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }
    var body: some View {
        Text(text).font(.body).lineSpacing(8).foregroundStyle(.primary.opacity(0.85))
    }
}

struct GlassCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        ZStack { content.padding(24) }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 1))
    }
}

struct ImpactComparator: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Label("Destructive Potential", systemImage: "bolt.fill")
                .font(.headline).foregroundStyle(.yellow)
            
            VStack(spacing: 20) {
                HStack(alignment: .center, spacing: 16) {
                    VStack {
                        Image(systemName: "circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(".22 Caliber Bullet").font(.caption).bold()
                        HStack {
                            Capsule().fill(.gray.opacity(0.5)).frame(width: 5, height: 8)
                            Text("360 Joules").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                
                HStack(alignment: .center, spacing: 16) {
                    VStack {
                        Image(systemName: "circle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                            .shadow(color: .orange.opacity(0.5), radius: 5)
                    }
                    .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("1cm Debris in Orbit").font(.headline).bold().foregroundStyle(.orange)
                        
                        GeometryReader { geo in
                            HStack(spacing: 0) {
                                Capsule()
                                    .fill(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * 0.9, height: 12)
                                Spacer()
                            }
                        }
                        .frame(height: 12)
                        
                        Text("35,000 Joules (Hand Grenade Force)").font(.caption).bold().foregroundStyle(.secondary)
                    }
                }
            }
            
            HStack {
                Text("Impact Multiplier:")
                    .font(.caption).foregroundStyle(.secondary)
                Text("~100x")
                    .font(.caption).fontWeight(.black).foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.gradient)
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Impact comparison. A .22 bullet has 360 Joules. A 1cm debris piece has 35,000 Joules, which is 100 times more powerful.")
    }
}

struct DebrisGrowthChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Object Count (>10cm)", systemImage: "chart.xyaxis.line")
                .font(.headline).foregroundStyle(.red)
            Chart {
                LineMark(x: .value("Y", "1990"), y: .value("C", 8000))
                LineMark(x: .value("Y", "2000"), y: .value("C", 10000))
                LineMark(x: .value("Y", "2010"), y: .value("C", 16000))
                LineMark(x: .value("Y", "2023"), y: .value("C", 27000))
            }
            .foregroundStyle(LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top))
            .frame(height: 150)
            .chartYAxis(.hidden)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Line chart showing debris growth from 8,000 in 1990 to 27,000 in 2023.")
    }
}

struct LoopDiagram: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Feedback Loop", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)
            
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    DiagramNode(text: "Impact")
                    ArrowIcon()
                    DiagramNode(text: "Debris")
                    ArrowIcon()
                    DiagramNode(text: "Density")
                }
                
                VStack(alignment: .leading) {
                    DiagramNode(text: "1. Impact")
                    ArrowIcon().rotationEffect(.degrees(90))
                    DiagramNode(text: "2. Debris")
                    ArrowIcon().rotationEffect(.degrees(90))
                    DiagramNode(text: "3. Density")
                }
            }
        }
    }
}

struct ArrowIcon: View {
    var body: some View {
        Image(systemName: "arrow.right")
            .font(.subheadline)
            .foregroundStyle(.secondary.opacity(0.5))
            .accessibilityHidden(true)
    }
}

struct DiagramNode: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.bold)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(.primary)
    }
}

struct TimelineView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                TimelineItem(year: "1978", title: "Hypothesis", desc: "Donald Kessler publishes theory warning of collisional cascades.")
                TimelineItem(year: "2009", title: "Iridium-33", desc: "First hypervelocity collision between two intact satellites.")
                TimelineItem(year: "2021", title: "ASAT Test", desc: "Russian anti-satellite missile test creates 1,500 trackable fragments.")
            }
            .padding(.bottom, 20)
            .padding(.horizontal, 2)
        }
    }
}

struct TimelineItem: View {
    let year: String, title: String, desc: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(year)
                .font(.title)
                .fontWeight(.black)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(width: 280, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(year): \(title). \(desc)")
    }
}

struct RemediationGrid: View {
    @Environment(\.dynamicTypeSize) var typeSize
    var columns: [GridItem] {
        typeSize > .xxLarge ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 300, maximum: .infinity), spacing: 20)]
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            BentoDetailCard(title: "Laser Broom", subtitle: "Ablation", icon: "laser.burst", colors: [.purple, .indigo]) {
                Text("Ground-based lasers fire pulses at debris to vaporize a thin surface layer.")
            }
            BentoDetailCard(title: "Harpoon Capture", subtitle: "Tethering", icon: "lasso", colors: [.orange, .red]) {
                Text("A chaser satellite fires a penetrator into a defunct target to reel it in.")
            }
            BentoDetailCard(title: "Magnetic Tugs", subtitle: "Induction", icon: "magnet", colors: [.blue, .cyan]) {
                Text("Using electromagnetic coils to induce eddy currents for touchless docking.")
            }
            BentoDetailCard(title: "Drag Sails", subtitle: "Passive Decay", icon: "wind", colors: [.green, .teal]) {
                Text("Deploying massive sails to increase atmospheric drag and speed up de-orbit.")
            }
        }
    }
}

struct BentoDetailCard<Content: View>: View {
    let title: String, subtitle: String, icon: String
    let colors: [Color]
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subtitle.uppercased()).font(.caption2).fontWeight(.bold).foregroundStyle(.secondary)
                    Text(title).font(.headline).fontWeight(.bold).fontDesign(.serif)
                }
                Spacer()
                Image(systemName: icon).font(.title2).accessibilityHidden(true)
                    .foregroundStyle(.white).frame(width: 44, height: 44)
                    .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(Circle())
            }
            Divider().opacity(0.5)
            content.font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.1), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) strategy. Type: \(subtitle).")
    }
}

struct BackgroundView: View {
    let isDarkMode: Bool
    var body: some View {
        ZStack {
            (isDarkMode ? Color(red: 0.05, green: 0.05, blue: 0.08) : Color(uiColor: .systemGroupedBackground))
                .ignoresSafeArea()
            if isDarkMode {
                GeometryReader { proxy in
                    ForEach(0..<30) { _ in
                        Circle().fill(.white.opacity(Double.random(in: 0.1...0.3)))
                            .frame(width: CGFloat.random(in: 1...3))
                            .position(x: CGFloat.random(in: 0...proxy.size.width), y: CGFloat.random(in: 0...proxy.size.height))
                    }
                }
                .ignoresSafeArea()
            }
        }
    }
}

struct ThemeToggle: View {
    @Binding var isDarkMode: Bool
    var body: some View {
        Button(action: { withAnimation(.spring) { isDarkMode.toggle() } }) {
            Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                .foregroundStyle(isDarkMode ? .yellow : .orange)
        }
        .accessibilityLabel("Toggle Appearance")
        .accessibilityValue(isDarkMode ? "Dark Mode" : "Light Mode")
    }
}

#Preview(traits: .landscapeLeft){
    KesslerDeepDiveView()
}
