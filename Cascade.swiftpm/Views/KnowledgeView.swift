import SwiftUI
import Charts

enum AppSection: String, CaseIterable, Identifiable {
    case hero = "Intro"
    case mechanics = "01. Mechanics"
    case situation = "02. The Situation"
    case remediation = "03. Remediation"
    case about = "04. About"
    case credits = "05. Credits"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .hero: return "What is Kessler Syndrome?"
        case .mechanics: return "Orbital Mechanics"
        case .situation: return "Current Situation"
        case .remediation: return "Remediation"
        case .about: return "About Cascade"
        case .credits: return "Sources & Credits"
        }
    }
    
    var subtitle: String {
        switch self {
        case .hero: return "A cascading threat to space exploration"
        case .mechanics: return "Physics of orbital collisions"
        case .situation: return "Where we stand today"
        case .remediation: return "Strategies to mitigate the situation"
        case .about: return "How this app approaches the subject"
        case .credits: return ""
        }
    }
    
    var icon: String {
        switch self {
        case .hero: return "globe.americas.fill"
        case .mechanics: return "arrow.3.trianglepath"
        case .situation: return "clock.arrow.circlepath"
        case .remediation: return "wrench.and.screwdriver.fill"
        case .about: return "info.circle.fill"
        case .credits: return "books.vertical.fill"
        }
    }
}

struct KesslerDeepDiveView: View {
    @State private var activeSection: AppSection? = .hero
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $activeSection) {
                ForEach(AppSection.allCases) { section in
                    NavigationLink(value: section) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(section.title)
                                    .font(.subheadline.weight(.medium))
                                if !section.subtitle.isEmpty {
                                    Text(section.subtitle)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: section.icon)
                        }
                    }
                }
            }
            .navigationTitle("Learn More")
            .listStyle(.sidebar)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            if let section = activeSection {
                ChapterContainerView(activeSection: section)
            } else {
                ContentUnavailableView("Select a Topic", systemImage: "book.closed.fill", description: Text("Choose a section from the sidebar to begin."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.ignoresSafeArea())
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: columnVisibility) { _, _ in
            columnVisibility = .all
        }
        .toolbar(.hidden)
        .preferredColorScheme(.dark)
    }
}

struct ChapterContainerView: View {
    let activeSection: AppSection
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(activeSection.title)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                    
                    if !activeSection.subtitle.isEmpty {
                        Text(activeSection.subtitle)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                .padding(.top)
                .accessibilityAddTraits(.isHeader)
                .accessibilityElement(children: .combine)
                
                Group {
                    switch activeSection {
                    case .hero:        OverviewChapter()
                    case .mechanics:   MechanicsChapter()
                    case .situation:   SituationChapter()
                    case .remediation: RemediationChapter()
                    case .about:       AboutChapter()
                    case .credits:     CreditsChapter()
                    }
                }
                
                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: 800, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .id(activeSection.id)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

struct OverviewChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("A self-reinforcing chain reaction in orbit — where every collision breeds the seeds of the next.")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.92))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            
            DefinitionCallout(
                term: "Kessler Syndrome",
                definition: "A theoretical scenario proposed by NASA scientist Donald J. Kessler in 1978, in which the density of objects in Low Earth Orbit becomes high enough that collisions between objects generate sufficient debris to trigger a self-sustaining cascade of further collisions. Each impact produces hundreds or thousands of new fragments, each capable of destroying another object.",
                source: "Kessler & Cour-Palais, Journal of Geophysical Research, 1978"
            )
            
            ScientificCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Why This Matters", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text("Global navigation, weather forecasting, climate observation, telecommunications, and disaster early-warning systems all depend on unimpeded access to Low Earth Orbit. If collision rates cross a critical threshold, entire orbital shells could become unusable for generations — not because of a single catastrophe, but because of a slow, compounding accumulation of debris.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(5)
                }
            }
            
            ScientificCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label("How to Use This Explainer", systemImage: "book.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        GuideRow(number: "1", text: "**The Mechanics** — Understand the physics: why collisions at orbital velocity are so destructive, and how one event triggers the next.")
                        GuideRow(number: "2", text: "**The Situation** — Review the historical timeline and current state of orbital debris, supported by tracking data.")
                        GuideRow(number: "3", text: "**Remediation** — Explore the engineering strategies being developed to slow, halt, or reverse debris growth.")
                    }
                }
            }
        }
    }
}

struct GuideRow: View {
    let number: String
    let text: LocalizedStringKey
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.blue)
                .frame(width: 22, height: 22)
                .background(Color.blue.opacity(0.15))
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
    }
}

struct DefinitionCallout: View {
    let term: String
    let definition: String
    let source: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 2)
                .fill(.blue)
                .frame(width: 3)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "text.book.closed.fill")
                        .foregroundStyle(.blue)
                    Text("Definition")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.blue)
                        .textCase(.uppercase)
                }
                
                Text(term)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                
                Text(definition)
                    .font(.subheadline)
                    .foregroundStyle(Color(white: 0.82))
                    .lineSpacing(5)
                
                Text("— \(source)")
                    .font(.caption.italic())
                    .foregroundStyle(.gray)
            }
            .padding(.vertical, 4)
        }
        .padding(20)
        .background(Color.blue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

struct MechanicsChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 44) {
            
            VStack(alignment: .leading, spacing: 24) {
                SectionLabel(text: "Feedback Loop")
                
                Text("The Cascade Effect")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Kessler Syndrome is not a single event — it is a self-reinforcing process. As the number of objects in a given orbital shell increases, the probability of collision rises proportionally. Each collision produces a cloud of fragments, and each fragment becomes a new potential projectile. Over time, the debris population grows exponentially, even without new launches.")
                
                TextParagraph("This positive feedback loop is the core of the Kessler hypothesis: beyond a critical density threshold, the debris environment becomes self-sustaining. Collisions generate debris faster than atmospheric drag can remove it, and the affected orbital band gradually becomes impassable.")
                
                ScientificCard { CausalFlowDiagram() }
                
                KeyConceptBox(
                    title: "Critical Density Threshold",
                    bodyText: "The point at which the rate of debris-generating collisions exceeds the rate of natural debris removal (primarily atmospheric drag). Below ~600 km, residual atmosphere clears fragments within years. Above ~800 km, debris can persist for centuries.",
                    icon: "exclamationmark.arrow.circlepath"
                )
            }
            
            Divider().overlay(.white.opacity(0.08))
            
            VStack(alignment: .leading, spacing: 24) {
                SectionLabel(text: "Collision Physics")
                
                Text("Orbital Energy")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Why are orbital collisions so catastrophic? The answer lies in velocity. Objects in Low Earth Orbit travel at approximately 7.5 km/s — over 27,000 km/h. At these speeds, kinetic energy scales dramatically, and even millimeter-sized particles carry enough energy to damage critical systems.")
                
                ScientificCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("KINETIC ENERGY EQUATION", systemImage: "function")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(white: 0.5))
                        
                        HStack(spacing: 4) {
                            Text("E")
                                .font(.title2.weight(.semibold).italic())
                                .foregroundStyle(.white)
                            Text("=")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.6))
                            Text("½")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.8))
                            Text("m")
                                .font(.title2.weight(.semibold).italic())
                                .foregroundStyle(.cyan)
                            Text("v²")
                                .font(.title2.weight(.semibold).italic())
                                .foregroundStyle(.orange)
                        }
                        .padding(.vertical, 8)
                        .accessibilityLabel("Kinetic energy equals one half times mass times velocity squared")
                        
                        Text("Because energy scales with the **square** of velocity, doubling the speed of impact quadruples the energy released. A 1 cm aluminum sphere at orbital velocity carries the kinetic energy of a hand grenade.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                }
                
                ScientificCard { ImpactComparisonView() }
                
                TextParagraph("At relative closing speeds that can reach 15 km/s in head-on scenarios, collisions do not merely dent or crack — they vaporize. The resulting debris cloud expands along the original orbit, creating a persistent hazard zone.")
            }
            
            Divider().overlay(.white.opacity(0.08))
            
            VStack(alignment: .leading, spacing: 24) {
                SectionLabel(text: "Detection Gap")
                
                Text("The Invisible Threat")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Space surveillance networks can reliably track objects larger than about 10 cm. However, fragments between 1 mm and 10 cm — too small to track but large enough to destroy — represent the most dangerous population. These objects are effectively invisible until impact.")
                
                ScientificCard { DebrisSizeClassView() }
            }
        }
    }
}

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold))
            .foregroundStyle(.blue)
            .tracking(1.2)
            .accessibilityAddTraits(.isHeader)
    }
}

struct KeyConceptBox: View {
    let title: String
    let bodyText: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 36, height: 36)
                .background(.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text(bodyText)
                    .font(.subheadline)
                    .foregroundStyle(Color(white: 0.78))
                    .lineSpacing(4)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.15), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

struct DebrisSizeClassView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("DEBRIS SIZE CLASSES", systemImage: "ruler.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(white: 0.5))
            
            VStack(spacing: 14) {
                DebrisSizeRow(
                    size: "> 10 cm",
                    count: "~32,000",
                    status: "Tracked",
                    statusColor: .green,
                    effect: "Catastrophic breakup",
                    proportion: 1.0
                )
                DebrisSizeRow(
                    size: "1 – 10 cm",
                    count: "~1,000,000",
                    status: "Partially Tracked",
                    statusColor: .yellow,
                    effect: "Mission-ending damage",
                    proportion: 0.7
                )
                DebrisSizeRow(
                    size: "1 mm – 1 cm",
                    count: "~130,000,000",
                    status: "Untracked",
                    statusColor: .red,
                    effect: "System degradation",
                    proportion: 0.35
                )
            }
        }
    }
}

struct DebrisSizeRow: View {
    let size: String
    let count: String
    let status: String
    let statusColor: Color
    let effect: String
    let proportion: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(size)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text(status)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 16) {
                Text(count)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 100, alignment: .leading)
                
                Text(effect)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(white: 0.15))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(statusColor.opacity(0.6))
                        .frame(width: geo.size.width * proportion, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(14)
        .background(Color(white: 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(size): estimated \(count) objects, \(status). Effect: \(effect)")
    }
}

struct SituationChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 44) {
            
            VStack(alignment: .leading, spacing: 24) {
                SectionLabel(text: "Historical Record")
                
                Text("Timeline of Key Events")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("The accumulation of orbital debris is not a recent phenomenon — it has been building since the dawn of the space age. Several pivotal events injected massive debris populations into heavily used orbital regions, each one demonstrating the fragility of the orbital commons.")
                
                TimelineVertical()
            }
            
            Divider().overlay(.white.opacity(0.08))
            
            VStack(alignment: .leading, spacing: 24) {
                SectionLabel(text: "Tracking Data")
                
                Text("Current Orbital Population")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Space surveillance networks — primarily the U.S. Space Surveillance Network and ESA's Space Debris Office — continuously track objects larger than 10 cm in Low Earth Orbit. The cataloged population has grown dramatically, with sharp inflections corresponding to fragmentation events.")
                
                ScientificCard { DebrisChart() }
                
                TextParagraph("Note the steep increase after 2007 (Fengyun-1C ASAT test) and 2009 (Iridium-Cosmos collision). These two events alone contributed over 5,000 trackable fragments to the catalog — more than decades of accumulated launch debris.")
            }
            
            Divider().overlay(.white.opacity(0.08))
            
            VStack(alignment: .leading, spacing: 24) {
                SectionLabel(text: "Operational Impact")
                
                Text("What This Means in Practice")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("The growing debris population has measurable consequences for active missions. Collision avoidance maneuvers are becoming routine, consuming propellant and reducing mission lifetime.")
                
                HStack(spacing: 14) {
                    OperationalStatCard(
                        value: "~50",
                        unit: "/ year",
                        label: "ISS Avoidance Maneuvers",
                        icon: "arrow.triangle.turn.up.right.diamond.fill",
                        accent: .cyan
                    )
                    OperationalStatCard(
                        value: "4×",
                        unit: "increase",
                        label: "Conjunction Alerts Since 2010",
                        icon: "bell.badge.fill",
                        accent: .orange
                    )
                }
                
                KeyConceptBox(
                    title: "Conjunction Assessment",
                    bodyText: "Every tracked object's trajectory is projected forward and compared against all others. When the predicted miss distance falls below a threshold (typically a few hundred meters), operators must decide whether to execute an avoidance maneuver — consuming irreplaceable fuel and interrupting mission operations.",
                    icon: "point.topleft.down.to.point.bottomright.curvepath"
                )
            }
        }
    }
}

struct OperationalStatCard: View {
    let value: String
    let unit: String
    let label: String
    let icon: String
    let accent: Color
    let accentColor = Color.cyan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accent)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.gray)
            }
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.15), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(unit): \(label)")
    }
}

struct RemediationChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            TextParagraph("Addressing orbital debris is a systems-level challenge requiring a three-pronged approach: prevent new debris generation through better design and operations, enforce responsible disposal of end-of-life spacecraft, and actively remove the highest-risk legacy objects before they fragment.")
            
            VStack(alignment: .leading, spacing: 24) {
                SectionLabel(text: "Natural Deorbit")
                
                Text("Our Greatest Ally: Atmospheric Drag")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Even at orbital altitudes, Earth's atmosphere does not end abruptly — it tapers off gradually. Residual gas molecules exert a faint but persistent drag force on orbiting objects. Over time, this drag lowers an object's altitude until it re-enters the atmosphere and burns up.")
                
                ScientificCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("ORBITAL DECAY BY ALTITUDE", systemImage: "arrow.down.to.line")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(white: 0.5))
                            .tracking(0.6)
                        
                        VStack(spacing: 12) {
                            DragLifetimeRow(altitude: "300 km", lifetime: "Weeks to months", intensity: 1.0, color: .green)
                            DragLifetimeRow(altitude: "400 km", lifetime: "~1 year", intensity: 0.7, color: .green)
                            DragLifetimeRow(altitude: "600 km", lifetime: "~25 years", intensity: 0.4, color: .yellow)
                            DragLifetimeRow(altitude: "800 km", lifetime: "~100–200 years", intensity: 0.15, color: .orange)
                            DragLifetimeRow(altitude: "1,000 km", lifetime: "~1,000+ years", intensity: 0.04, color: .red)
                        }
                        
                        Text("Solar activity cycles cause the upper atmosphere to expand and contract, significantly affecting drag rates. During solar maxima, decay accelerates; during minima, it slows.")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .lineSpacing(3)
                            .padding(.top, 4)
                    }
                }
                
                TextParagraph("Below approximately 600 km, atmospheric drag is effective enough to clear most debris within decades. This is why the International Space Station orbits at ~400 km — any debris generated at that altitude is naturally swept away relatively quickly. The challenge lies in higher orbits, where drag is negligible and debris persists for centuries.")
            }
            
            Divider().overlay(.white.opacity(0.08))
            
            VStack(alignment: .leading, spacing: 24) {
                SectionLabel(text: "Engineered Solutions")
                
                Text("Active Removal Technologies")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Where atmospheric drag alone is insufficient, engineered interventions are required. Several approaches are under development, each targeting different aspects of the debris problem.")
                
                VStack(spacing: 20) {
                    StrategyCard(
                        title: "Drag Augmentation",
                        category: "Passive Deorbit",
                        icon: "wind",
                        accent: .green,
                        description: "Deployable drag sails or inflatable structures dramatically increase a spacecraft's cross-sectional area at end of life, accelerating orbital decay through atmospheric drag. These devices are lightweight and can be integrated into satellite design from the outset.",
                        mechanism: "By increasing the area-to-mass ratio, atmospheric drag forces multiply, reducing deorbit time from centuries to years — even at 700–800 km altitude. Several commercial systems are now flight-proven.",
                        maturity: "Flight-Proven",
                        maturityLevel: 0.8
                    )
                    
                    StrategyCard(
                        title: "Harpoon & Net Capture",
                        category: "Active Debris Removal",
                        icon: "lasso",
                        accent: .orange,
                        description: "A chaser spacecraft approaches a large defunct satellite or rocket body and secures it using a tethered harpoon or deployable net. Once captured, the combined system performs a controlled deorbit burn.",
                        mechanism: "The RemoveDEBRIS mission (2018) successfully demonstrated both net capture and harpoon penetration in orbit. ESA's ClearSpace-1, planned for 2026, aims to be the first full-scale removal mission.",
                        maturity: "Demonstrated",
                        maturityLevel: 0.55
                    )
                    
                    StrategyCard(
                        title: "Laser Ablation",
                        category: "Ground-Based Impulse",
                        icon: "dot.radiowaves.left.and.right",
                        accent: .purple,
                        description: "High-powered ground-based or orbital lasers target a debris object's surface, vaporizing a thin layer of material. The resulting gas jet acts as a miniature thruster, applying a small but precise impulse to the object.",
                        mechanism: "Repeated laser passes over days or weeks gradually lower the object's perigee until atmospheric drag completes the deorbit. No physical contact is required.",
                        maturity: "Experimental",
                        maturityLevel: 0.25
                    )
                    
                    StrategyCard(
                        title: "Magnetic Eddy-Current Tugs",
                        category: "Contactless Interaction",
                        icon: "magnet",
                        accent: .blue,
                        description: "Tumbling debris objects are dangerous to approach and impossible to dock with. Magnetic tugs generate rotating magnetic fields that induce eddy currents in the target's conductive body, producing forces and torques at a safe standoff distance.",
                        mechanism: "Contactless detumbling stabilizes the target for subsequent capture, or sustained magnetic braking can directly lower the orbit over time. No mechanical attachment is needed.",
                        maturity: "Research",
                        maturityLevel: 0.15
                    )
                }
            }
            
            Divider().overlay(.white.opacity(0.08))
            
            ScientificCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label("The 25-Year Guideline", systemImage: "calendar.badge.clock")
                        .font(.headline).foregroundStyle(.white)
                    
                    Text("The Inter-Agency Space Debris Coordination Committee (IADC) recommends that all LEO spacecraft be deorbited within 25 years of mission end. In 2022, the U.S. Federal Communications Commission adopted a stricter 5-year rule for U.S.-licensed satellites. Compliance remains voluntary for many operators worldwide.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(5)
                }
            }
        }
    }
}

struct DragLifetimeRow: View {
    let altitude: String
    let lifetime: String
    let intensity: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(altitude)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 70, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(white: 0.12))
                    Capsule()
                        .fill(color.opacity(0.6))
                        .frame(width: max(geo.size.width * intensity, 4))
                }
            }
            .frame(height: 5)
            .clipShape(Capsule())
            
            Text(lifetime)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.gray)
                .frame(width: 120, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("At \(altitude): debris lifetime approximately \(lifetime)")
    }
}

struct AboutChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 44) {
            
            VStack(alignment: .leading, spacing: 24) {
                SectionLabel(text: "Under the Hood")
                
                Text("Simulation Architecture")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("Cascade runs a custom deterministic physics engine written in Swift. To maintain 60 FPS on mobile devices while tracking thousands of objects, the simulation employs specific architectural patterns and mathematical simplifications.")
                
                ScientificCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Label("Engine Specs", systemImage: "cpu.fill")
                            .font(.headline).foregroundStyle(.white)
                        
                        VStack(spacing: 12) {
                            ModelParam(name: "Integrator", value: "Semi-Implicit Euler", detail: "Symplectic integration for stable orbits")
                            Divider().overlay(.white.opacity(0.08))
                            ModelParam(name: "Collision Detection", value: "Spatial Hashing", detail: "O(n) lookup via uniform grid partition")
                            Divider().overlay(.white.opacity(0.08))
                            ModelParam(name: "Parallelization", value: "Multithreaded", detail: "Physics logic distributed across CPU cores")
                            Divider().overlay(.white.opacity(0.08))
                            ModelParam(name: "Rendering", value: "RealityKit", detail: "Instanced mesh particles for debris clouds")
                        }
                    }
                }
            }
            
            Divider().overlay(.white.opacity(0.08))
            
            VStack(alignment: .leading, spacing: 24) {
                SectionLabel(text: "Model Simplifications")
                
                Text("Compromises & Constraints")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                TextParagraph("A full-fidelity orbital simulation requires supercomputers. To run locally on your device, Cascade makes three major physics compromises:")
                
                VStack(spacing: 20) {
                    SimplificationCard(
                        title: "No Debris-Debris Collisions",
                        icon: "bolt.slash.fill",
                        description: "The simulation calculates Satellite-vs-Satellite and Satellite-vs-Debris impacts. However, debris fragments do not collide with each other. Calculating interactions between thousands of debris particles would grow exponentially (O(n²)), stalling the engine."
                    )
                    
                    SimplificationCard(
                        title: "Representative Density",
                        icon: "square.grid.3x3.middle.filled",
                        description: "We cannot render the 100+ million actual fragments in orbit. Instead, Cascade uses 'Representative Debris': one visible particle in the simulation represents a dense cloud of thousands of real-world lethal fragments."
                    )
                    
                    SimplificationCard(
                        title: "Idealized Gravity",
                        icon: "circle.dashed",
                        description: "The simulation treats Earth as a perfect sphere. It omits 'J2 Perturbations' (the effect of Earth's equatorial bulge) and atmospheric drag. Objects only deorbit if they physically collide with the planet's surface."
                    )
                }
            }
            
            Divider().overlay(.white.opacity(0.08))
            
            VStack(alignment: .leading, spacing: 24) {
                SectionLabel(text: "Learning Outcomes")
                
                Text("What Cascade can teach you")
                    .font(.title2.bold()).foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 12) {
                    LearningObjective(text: "Understand why collision cascades are self-reinforcing above a critical density threshold")
                    LearningObjective(text: "Appreciate the role of orbital velocity in making even small debris lethal to other satellites")
                    LearningObjective(text: "Visualize how debris spreads from a single point of impact into a planetary ring over time")
                    LearningObjective(text: "Recognize that orbital space is a finite resource requiring active stewardship")
                }
            }
        }
    }
}

struct SimplificationCard: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 40, height: 40)
                .background(.orange.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct CreditsChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            
            TextParagraph("The information presented in this explainer is drawn from publicly available scientific publications, institutional reports, and official data repositories maintained by international space agencies and reputable non-profit organizations.")
            
            ScientificCard {
                VStack(alignment: .leading, spacing: 18) {
                    CreditSection(role: "Foundational Publications", entries: [
                        "D.J. Kessler & B.G. Cour-Palais — \"Collision Frequency of Artificial Satellites: The Creation of a Debris Belt\" (Journal of Geophysical Research, Vol. 83, 1978)",
                        "J.-C. Liou & N.L. Johnson — \"Instability of the Present LEO Satellite Populations\" (Advances in Space Research, Vol. 41, 2008)",
                        "H. Klinkrad — \"Space Debris: Models and Risk Analysis\" (Springer-Verlag, 2006)"
                    ])
                    
                    Divider().overlay(.white.opacity(0.08))
                    
                    CreditSection(role: "Institutional Data Sources", entries: [
                        "NASA Orbital Debris Program Office — Orbital Debris Quarterly News",
                        "ESA Space Debris Office — Annual Space Environment Report (2024)",
                        "IADC Space Debris Mitigation Guidelines (Rev. 2, 2020)",
                        "U.S. Space Surveillance Network — Public catalog data via Space-Track.org"
                    ])
                    
                    Divider().overlay(.white.opacity(0.08))
                    
                    CreditSection(role: "Remediation Technology References", entries: [
                        "S. Forshaw et al. — \"RemoveDEBRIS: An In-Orbit Active Debris Removal Demonstration Mission\" (Acta Astronautica, Vol. 127, 2016)",
                        "ESA ClearSpace-1 Mission Overview — esa.int/clearspace",
                        "C. Bombardelli & J. Peláez — \"Ion Beam Shepherd for Contactless Space Debris Removal\" (Journal of Guidance, Control, and Dynamics, Vol. 34, 2011)"
                    ])
                }
            }
            
            ScientificCard {
                VStack(alignment: .leading, spacing: 18) {
                    CreditSection(role: "Imagery & Orbital Data", entries: [
                        "Earth texture from NASA Earth Observatory images by Reto Stöckli, based on data from NASA and NOAA.",
                        "ESA Space Debris User Portal — discosweb.esoc.esa.int",
                        "CelesTrak (T.S. Kelso) — TLE catalog and orbital element data"
                    ])
                }
            }
        }
    }
    
    func CreditSection(role: String, entries: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(role)
                .font(.caption.weight(.bold))
                .foregroundStyle(.blue)
                .textCase(.uppercase)
                .tracking(0.8)
            
            ForEach(entries, id: \.self) { entry in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 4, height: 4)
                        .padding(.top, 7)
                    Text(entry)
                        .font(.subheadline)
                        .foregroundStyle(Color(white: 0.82))
                        .lineSpacing(3)
                }
            }
        }
    }
}

struct ModelParam: View {
    let name: String
    let value: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.cyan)
        }
        .accessibilityElement(children: .combine)
    }
}

struct LearningObjective: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundStyle(.green)
                .padding(.top, 1)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color(white: 0.85))
                .lineSpacing(3)
        }
        .accessibilityElement(children: .combine)
    }
}

struct TextParagraph: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }
    
    var body: some View {
        Text(text)
            .font(.body)
            .lineSpacing(6)
            .foregroundStyle(Color(white: 0.85))
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct ScientificCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content.padding(22)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct ImpactComparisonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Label("ENERGY COMPARISON", systemImage: "bolt.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(white: 0.5))
            
            Text("Kinetic energy of a 1 cm aluminum sphere at orbital velocity, compared to familiar references.")
                .font(.caption)
                .foregroundStyle(.gray)
                .lineSpacing(3)
            
            VStack(spacing: 18) {
                EnergyBar(label: ".22 LR Bullet", energy: "~140 J", fraction: 0.004, color: Color.gray.opacity(0.5), highlight: false)
                EnergyBar(label: "Baseball Pitch", energy: "~155 J", fraction: 0.0044, color: Color.gray.opacity(0.5), highlight: false)
                EnergyBar(label: "9mm Bullet", energy: "~520 J", fraction: 0.015, color: Color.gray.opacity(0.6), highlight: false)
                EnergyBar(label: "1 cm Debris (7.5 km/s)", energy: "~35,000 J", fraction: 1.0, color: .orange, highlight: true)
            }
            
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                Text("A 1 cm fragment carries roughly **250×** the energy of a bullet.")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(.top, 4)
        }
        .accessibilityElement(children: .contain)
    }
}

struct EnergyBar: View {
    let label: String
    let energy: String
    let fraction: Double
    let color: Color
    let highlight: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption.weight(highlight ? .bold : .semibold))
                    .foregroundStyle(highlight ? .white : Color(white: 0.65))
                
                Spacer()
                
                Text(energy)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(highlight ? .orange : Color(white: 0.55))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(white: 0.1))
                    
                    Capsule()
                        .fill(
                            highlight
                            ? LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [color, color], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: max(geo.size.width * fraction, 4))
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(energy)")
    }
}

struct DebrisChart: View {
    struct DebrisDataPoint: Identifiable {
        let id = UUID()
        let year: Int
        let count: Int
        let annotation: String?
    }
    
    let data: [DebrisDataPoint] = [
        .init(year: 1960, count: 200, annotation: nil),
        .init(year: 1965, count: 600, annotation: nil),
        .init(year: 1970, count: 1800, annotation: nil),
        .init(year: 1975, count: 3400, annotation: nil),
        .init(year: 1980, count: 5000, annotation: nil),
        .init(year: 1985, count: 6200, annotation: nil),
        .init(year: 1990, count: 7500, annotation: nil),
        .init(year: 1995, count: 8500, annotation: nil),
        .init(year: 2000, count: 9700, annotation: nil),
        .init(year: 2005, count: 10500, annotation: nil),
        .init(year: 2007, count: 13500, annotation: "Fengyun-1C ASAT"),
        .init(year: 2009, count: 16000, annotation: "Iridium-Cosmos"),
        .init(year: 2012, count: 17000, annotation: nil),
        .init(year: 2015, count: 18000, annotation: nil),
        .init(year: 2018, count: 20000, annotation: nil),
        .init(year: 2020, count: 23000, annotation: nil),
        .init(year: 2022, count: 27000, annotation: nil),
        .init(year: 2024, count: 32000, annotation: nil)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Cataloged Objects in Earth Orbit")
                    .font(.headline).foregroundStyle(.white)
                Text("Objects larger than 10 cm tracked by space surveillance networks, 1960–2024.")
                    .font(.caption).foregroundStyle(.gray)
                    .lineSpacing(3)
            }
            .padding(.bottom, 16)
            
            Chart {
                ForEach(data) { point in
                    AreaMark(
                        x: .value("Year", point.year),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.25), Color.cyan.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(Color.cyan)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                }
                
                RuleMark(x: .value("Event", 2007))
                    .foregroundStyle(.orange.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Fengyun-1C")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                
                RuleMark(x: .value("Event", 2009))
                    .foregroundStyle(.red.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Iridium-Cosmos")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
            }
            .chartXScale(domain: 1960...2026)
            .chartYScale(domain: 0...36000)
            .chartXAxis {
                AxisMarks(values: stride(from: 1960, through: 2024, by: 10).map { $0 }) { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.06))
                    AxisValueLabel {
                        if let intVal = value.as(Int.self) {
                            Text("'\(intVal % 100, specifier: "%02d")")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: stride(from: 0, through: 35000, by: 5000).map { $0 }) { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.06))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text(intValue >= 1000 ? "\(intValue / 1000)k" : "\(intValue)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
            }
            .frame(height: 260)
            .accessibilityLabel("Line chart showing growth of tracked orbital objects from about 200 in 1960 to over 32,000 in 2024, with sharp increases after the 2007 Fengyun-1C test and 2009 Iridium-Cosmos collision.")
        }
    }
}

struct TimelineVertical: View {
    let events = [
        ("1957", "Sputnik 1", "The first artificial satellite launch marks the beginning of orbital debris accumulation."),
        ("1978", "The Kessler Hypothesis", "Donald Kessler (NASA) publishes 'Collision Frequency of Artificial Satellites', predicting the cascade effect."),
        ("1996", "Cerise Collision", "First verified collision between an active satellite and debris (from an Ariane rocket body)."),
        ("2007", "Fengyun-1C Test", "China conducts an anti-satellite missile test, instantly adding ~3,500 trackable fragments."),
        ("2009", "Iridium vs Cosmos", "First major hypervelocity collision between two intact satellites (active Iridium 33 and defunct Cosmos 2251)."),
        ("2021", "Nudol Test", "Russian ASAT test destroys Cosmos 1408, creating a debris cloud requiring ISS avoidance maneuvers."),
        ("2024", "Current Status", "Over 32,000 objects >10cm are now tracked, with millions of smaller, untrackable lethal fragments.")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(index == 0 ? Color.blue : Color.gray.opacity(0.5))
                            .frame(width: 10, height: 10)
                            .background(
                                Circle()
                                    .fill(index == 0 ? Color.blue.opacity(0.3) : Color.clear)
                                    .frame(width: 20, height: 20)
                            )
                        
                        if index != events.count - 1 {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 1)
                                .frame(maxHeight: .infinity)
                                .padding(.vertical, 4)
                        }
                    }
                    .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.0)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(index == 0 ? .blue : .gray)
                        Text(event.1)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(event.2)
                            .font(.subheadline)
                            .foregroundStyle(Color(white: 0.8))
                            .padding(.bottom, 30)
                    }
                }
            }
        }
    }
}

struct StrategyCard: View {
    let title: String
    let category: String
    let icon: String
    let accent: Color
    let description: String
    let mechanism: String
    var maturity: String = ""
    var maturityLevel: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(accent)
                        .tracking(0.6)
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(accent)
                    .frame(width: 44, height: 44)
                    .background(accent.opacity(0.12))
                    .clipShape(Circle())
            }
            
            if !maturity.isEmpty {
                HStack(spacing: 10) {
                    Text("Readiness")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.gray)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(white: 0.12))
                            Capsule()
                                .fill(accent.opacity(0.7))
                                .frame(width: geo.size.width * maturityLevel)
                        }
                    }
                    .frame(height: 4)
                    .clipShape(Capsule())
                    
                    Text(maturity)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(accent)
                }
                .accessibilityLabel("Technology readiness: \(maturity)")
            }
            
            Divider().overlay(Color.white.opacity(0.08))
            
            VStack(alignment: .leading, spacing: 16) {
                Text(description)
                    .font(.body)
                    .foregroundStyle(Color(white: 0.82))
                    .lineSpacing(5)
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "gearshape.2.fill")
                        .font(.caption)
                        .foregroundStyle(accent.opacity(0.8))
                        .padding(.top, 4)
                    
                    Text(mechanism)
                        .font(.callout)
                        .foregroundStyle(Color(white: 0.88))
                        .lineSpacing(4)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accent.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(accent.opacity(0.1), lineWidth: 1)
                )
            }
        }
        .padding(22)
        .background(Color(white: 0.07))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }
}

struct CausalFlowDiagram: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Label("THE CASCADE LOOP", systemImage: "point.3.filled.connected.trianglepath.dotted")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(white: 0.5))
                .tracking(0.6)
            
            HStack(spacing: 0) {
                flowNode(icon: "cube.fill", title: "Density\nIncreases", color: .blue)
                flowConnector
                flowNode(icon: "burst.fill", title: "Collision\nOccurs", color: .orange)
                flowConnector
                flowNode(icon: "aqi.medium", title: "Fragments\nSpread", color: .gray)
                flowConnector
                flowNode(icon: "exclamationmark.triangle.fill", title: "Risk\nEscalates", color: .red)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "arrow.turn.up.left")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.6))
                Text("Each stage feeds the next — the loop is self-reinforcing above the critical threshold.")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .lineSpacing(2)
            }
            .padding(.top, 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cascade loop diagram: increasing density leads to collisions, which create fragments, which escalate risk, which further increases density. The loop is self-reinforcing.")
    }
    
    var flowConnector: some View {
        VStack {
            Image(systemName: "chevron.right")
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.25))
        }
        .frame(width: 24)
    }
    
    func flowNode(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    KesslerDeepDiveView()
}
