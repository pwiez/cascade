//
//  CreditsChapter.swift
//  Cascade
//
//  Created by Pedro Wiezel on 15/02/26.
//

import SwiftUI

struct CreditsChapter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {

            TextParagraph("Cascade's premise and the data shown here are drawn from publicly available research, scientific publications, institutional reports, and official repositories maintained by space agencies and reputable organizations.")

            VStack(alignment: .leading, spacing: 40) {

                VStack(alignment: .leading, spacing: 24) {
                    EditorialSectionHeader(title: "Assets")

                    TextParagraph("• Earth's texture map with clouds was created by Tom Patterson, based on NASA imaging.\n• Earth normal and specular maps by Solar System Scope, based on NASA imaging.")
                }

                VStack(alignment: .leading, spacing: 24) {
                    EditorialSectionHeader(title: "Papers, Publications and Reports")

                    TextParagraph("• Kessler, D. J., & Cour-Palais, B. G. (1978). Collision frequency of artificial satellites: The creation of a debris belt. *Journal of Geophysical Research*, *83*(A6), 2637–2646.\n• Kessler, D. J., Johnson, N. L., Liou, J.-C., & Matney, M. (2010). The Kessler syndrome: Implications to future space operations. *Advances in the Astronautical Sciences*, *137*.\n• Liou, J.-C., & Johnson, N. L. (2006). Risks in space from orbiting debris. *Science*, *311*(5759), 340–341.\n• Portree, D. S. (1999). *Orbital debris: A chronology* (NASA/TP-1999-208856). National Aeronautics and Space Administration.")
                }

                VStack(alignment: .leading, spacing: 24) {
                    EditorialSectionHeader(title: "Institutional Data Sources")

                    TextParagraph("• Orbital Debris Quarterly News, by the NASA Orbital Debris Program Office.\n• The 2024 Annual Space Environment Report by the European Space Agency's Space Debris Office.\n• 2020 IADC Debris Mitigation Guidelines, by the Inter-Agency Space Debris Coordination Committee.\n• Mitigation of Orbital Debris in the New Space Age, by the U.S. Federal Communications Commission, 2022.\n• Catalog data by the U.S. Space Surveillance Network, available on Space-Track.org.")
                }

                VStack(alignment: .leading, spacing: 24) {
                    EditorialSectionHeader(title: "Remediation Technology References")

                    TextParagraph("• Locke, J., Colvin, T. J., Ratliff, L., Abdul-Hamid, A., & Samples, C. (2024). *Cost and benefit analysis of mitigating, tracking, and remediating orbital debris*. National Aeronautics and Space Administration, Office of Technology, Policy, and Strategy.\n• Forshaw, J. L., et al. (2016). RemoveDEBRIS: An in-orbit active debris removal demonstration mission. *Acta Astronautica*, *127*.\n• European Space Agency's ClearSpace-1 mission overview, available on esa.int/Space_Safety/ClearSpace-1")
                }
            }
        }
    }
}
