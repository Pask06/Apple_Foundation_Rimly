import Foundation

struct BowlData {
    static let categories = [
        BowlCategory(name: "Jambati Bowl", bowls: [
            SingingBowl(categoryName: "Jambati Bowl", note: "Re3", frequency: 452, imageName: "JD154", rubAudio: "JD154Rub", strikeAudio: "JD154Strike"),
            SingingBowl(categoryName: "Jambati Bowl", note: "Ti4", frequency: 508, imageName: "JD_26", rubAudio: "JD_26Rub", strikeAudio: "JD_26Strike"),
            SingingBowl(categoryName: "Jambati Bowl", note: "Mib4", frequency: 303, imageName: "JG_120", rubAudio: "JG_120Rub", strikeAudio: "JG_120Strike")
        ]),
        BowlCategory(name: "Mani Bowl", bowls: [
            SingingBowl(categoryName: "Mani Bowl", note: "Re5", frequency: 593, imageName: "MAD9", rubAudio: "MAD9Rub", strikeAudio: "MAD9Strike"),
            SingingBowl(categoryName: "Mani Bowl", note: "Re5", frequency: 1690, imageName: "MAD8", rubAudio: "MAD8Rub", strikeAudio: "MAD8Strike"),
            SingingBowl(categoryName: "Mani Bowl", note: "Fa5", frequency: 701, imageName: "MAF6", rubAudio: "MAF6Rub", strikeAudio: "MAF6Strike")
        ]),
        BowlCategory(name: "Manipuri Bowl", bowls: [
            SingingBowl(categoryName: "Manipuri Bowl", note: "Sol3", frequency: 532, imageName: "MPF_94", rubAudio: "MPF_94Rub", strikeAudio: "MPF_94Strike"),
            SingingBowl(categoryName: "Manipuri Bowl", note: "Re#", frequency: 312, imageName: "MPD_62", rubAudio: "MPD_62Rub", strikeAudio: "MPD_62Strike"),
            SingingBowl(categoryName: "Manipuri Bowl", note: "Sol4", frequency: 1120, imageName: "MPG56", rubAudio: "MPG56Rub", strikeAudio: "MPG56Strike")
        ]),
        BowlCategory(name: "Lingam Bowl", bowls: [
            SingingBowl(categoryName: "Lingam Bowl", note: "Mib4", frequency: 299, imageName: "SLD_7", rubAudio: "SLD_7Rub", strikeAudio: "SLD_7Strike"),
            SingingBowl(categoryName: "Lingam Bowl", note: "Fa#", frequency: 378, imageName: "SLF_5", rubAudio: "SLF_5Rub", strikeAudio: "SLF_5Strike"),
        ]),
        BowlCategory(name: "Thadobati Bowl", bowls: [
            SingingBowl(categoryName: "Thadobati Bowl", note: "Ti3", frequency: 249, imageName: "TB478", rubAudio: "TB478Rub", strikeAudio: "TB478Strike"),
            SingingBowl(categoryName: "Thadobati Bowl", note: "Re5", frequency: 586, imageName: "TCD464", rubAudio: "TCD464Rub", strikeAudio: "TCD464Strike"),
            SingingBowl(categoryName: "Thadobati Bowl", note: "Db6", frequency: 387, imageName: "TCG441", rubAudio: "TCG441Rub", strikeAudio: "TCG441Strike")
        ])
    ]
}
