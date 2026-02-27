import SwiftUI

struct CreditsChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            
            TextParagraph("Cascade's premise and the data shown here are drawn from publicly available research, scientific publications, institutional reports, and official repositories maintained by space agencies and reputable organizations.")
            
            VStack(alignment: .leading, spacing: 40) {
                
                VStack(alignment: .leading, spacing: 24) {
                    Text("Assets")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    TextParagraph("• Earth's texture map with clouds is in the public domain, and was created by Tom Patterson based on NASA imaging curated by Reto Stöckli. They are available on the website shadedrelief.com.")
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    Text("Papers, Publications and Reports")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    TextParagraph("• Kessler, D. J., & Cour-Palais, B. G. (1978). Collision frequency of artificial satellites: The creation of a debris belt. *Journal of Geophysical Research*, *83*.\n• Liou, J., & Johnson, N. L. (2006b). Risks in Space from Orbiting Debris. Science, 311(5759), 340–341.\n• Portree, D. S. (1999). Orbital debris: A chronology (Vol. 208856). NASA.")
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    Text("Institutional Data Sources")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    TextParagraph("• NASA Orbital Debris Program Office. *Orbital debris quarterly news*.\n• European Space Agency Space Debris Office. (2024). *Annual space environment report*.\n• Inter-Agency Space Debris Coordination Committee. (2020). *IADC space debris mitigation guidelines*.\n• U.S. Federal Communications Commission. (2022). *Space Innovation; Mitigation of Orbital Debris in the New Space Age*.\n• U.S. Space Surveillance Network. *Public catalog data*. Space-Track.org.")
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    Text("Remediation References")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    TextParagraph("• Locke, J., Colvin, T. J., Ratliff, L., Abdul-Hamid, A., & Samples, C. (2024). Cost and benefit analysis of mitigating, tracking, and remediating orbital debris. *Cost and Benefit Analysis of Mitigating, Tracking, and Remediating Orbital Debris.*\n• Forshaw, J. L., et al. (2016). RemoveDEBRIS: An in-orbit active debris removal demonstration mission. *Acta Astronautica*, *127*.\n• European Space Agency. *ClearSpace-1 mission overview*. esa.int/Space_Safety/ClearSpace-1")
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
                        .fill(.primary.opacity(0.3))
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
