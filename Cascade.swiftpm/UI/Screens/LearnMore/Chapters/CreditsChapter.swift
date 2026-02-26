import SwiftUI

struct CreditsChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            
            TextParagraph("Cascade's premise as well as the information and data shown here are all drawn from publicly available scientific publications, institutional reports, and official data repositories maintained by international space agencies and reputable non-profit organizations.")
            
            ScientificCard {
                VStack(alignment: .leading, spacing: 18) {
                    CreditSection(role: "Papers and Publications", entries: [
                        "Kessler, D. J., & Cour-Palais, B. G. (1978). Collision frequency of artificial satellites: the creation of a debris belt. *Journal of Geophysical Research*, *83*.",
                        "Liou, J.-C., & Johnson, N. L. (2006). Risks in space from orbiting debris. *Science*, *311*(5759), 340–341.",
                        "Klinkrad, H. (2006). *Space debris: models and risk analysis*. Springer Science & Business Media."
                    ])
                    
                    Divider().cascadeDivider()
                    
                    CreditSection(role: "Assets", entries: [
                        "Earth texture and cloud map by Tom Patterson (www.shadedrelief.com), based on NASA Earth Observatory images by Reto Stöckli.",
                    ])
                    
                    Divider().cascadeDivider()
                    
                    
                    CreditSection(role: "Orbital Data", entries: [
                        "CelesTrak (T.S. Kelso) — TLE catalog and orbital element data"
                    ])
                    
                    Divider().cascadeDivider()
                    
                    CreditSection(role: "Institutional Data Sources", entries: [
                        "NASA Orbital Debris Program Office. (n.d.). *Orbital debris quarterly news*.",
                        "European Space Agency Space Debris Office. (2024). *Annual space environment report*.",
                        "U.S. Space Surveillance Network. (n.d.). *Public catalog data* [Data set]. Space-Track.org.",
                        "World Economic Forum. (2026). *Clear orbit, secure future: a call to action on space debris*."
                    ])
                    
                    Divider().cascadeDivider()
                    
                    CreditSection(role: "Remediation Technology References", entries: [
                        "Forshaw, J. L., et al. (2016). RemoveDEBRIS: An in-orbit active debris removal demonstration mission. *Acta Astronautica*, *127*.",
                        "European Space Agency. (n.d.). *ClearSpace-1 mission overview*. esa.int/Space_Safety/ClearSpace-1",
                        "Astroscale. (2024). *ADRAS-J mission overview: World's first rendezvous with large space debris*. astroscale.com/missions/adras-j"
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
                        
                        Text(LocalizedStringKey(entry))
                            .font(.subheadline)
                            .foregroundStyle(CascadeTheme.bodyText)
                            .lineSpacing(3)
                    }
                }
            }
        }
}
