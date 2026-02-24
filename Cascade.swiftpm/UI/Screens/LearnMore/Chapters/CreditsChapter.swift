import SwiftUI

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
                    
                    Divider().cascadeDivider()
                    
                    CreditSection(role: "Institutional Data Sources", entries: [
                        "NASA Orbital Debris Program Office — Orbital Debris Quarterly News",
                        "ESA Space Debris Office — Annual Space Environment Report (2024)",
                        "IADC Space Debris Mitigation Guidelines (Rev. 2, 2020)",
                        "U.S. Space Surveillance Network — Public catalog data via Space-Track.org"
                    ])
                    
                    Divider().cascadeDivider()
                    
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
                        .foregroundStyle(CascadeTheme.bodyText)
                        .lineSpacing(3)
                }
            }
        }
    }
}
