//
//  ReferenceData.swift
//  StockmansWallet
//
//  Reference data from Appendix C
//

import Foundation

struct ReferenceData {
    // MARK: - Breeds (From ADD HERD Flow PDF)
    static let cattleBreeds = [
        "Angus X", "Angus", "Black Baldy", "Black Hereford",
        "Brahman", "Brangus", "Charbray", "Charolais", "Charolais X Angus",
        "Cross Breed", "Droughtmaster", "European Cross", "Friesian",
        "Friesian Cross", "Hereford", "Hereford X Friesian", "Limousin",
        "Limousin X Friesian", "Murray Grey", "Murray Grey X Friesian",
        "Poll Hereford", "Red Angus", "Santa Gertrudis", "Shorthorn",
        "Shorthorn X Friesian", "Simmental", "Wagyu"
    ]
    
    static let sheepBreeds = [
        "Merino", "Poll Merino", "Dohne Merino", "SAMM",
        "Border Leicester", "Poll Dorset", "White Suffolk", "Suffolk",
        "Dorper", "White Dorper", "Aussie White", "Damara",
        "Wiltipoll", "Texel", "Hampshire Down", "Southdown",
        "Corriedale", "East Friesian", "Perendale", "Romney",
        "Wiltshire Horn"
    ]
    
    static let pigBreeds = [
        "Landrace", "Large White", "Duroc", "Tamworth",
        "Wessex Saddleback", "Hampshire", "Berkshire",
        "Australian Miniature Pig", "Gloucestershire Old Spot"
    ]
    
    static let goatBreeds = [
        "Saanen", "Toggenburg", "British Alpine", "Anglo Nubian",
        "Australian Cashmere", "Australian Heritage Angora",
        "Australian Heritage Anglo-Nubian", "Australian Rangeland Goat",
        "Australian Miniature", "Boer", "Nigerian Dwarf"
    ]
    
    // MARK: - Saleyards (Appendix C.2)
    static let saleyards = [
        "Wagga Wagga Livestock Marketing Centre",
        "Dubbo Regional Livestock Market",
        "Forbes Central West Livestock Exchange",
        "Tamworth Regional Livestock Exchange",
        "Carcoar Central Tablelands Livestock Exchange",
        "Yass South Eastern Livestock Exchange",
        "Inverell Regional Livestock Exchange",
        "Roma Saleyards",
        "Dalby Regional Saleyards",
        "Gracemere Central Queensland Livestock Exchange",
        "Charters Towers Dalrymple Saleyards",
        "Emerald Saleyards",
        "Blackall Saleyards",
        "Warwick Saleyards",
        "Wodonga (Barnawartha) Northern Victoria Livestock Exchange",
        "Leongatha Saleyards",
        "Pakenham Victorian Livestock Exchange",
        "Mortlake Western Victorian Livestock Exchange",
        "Ballarat Central Victoria Livestock Exchange",
        "Shepparton Regional Saleyards",
        "Warrnambool Livestock Exchange",
        "Mount Gambier Saleyards",
        "Naracoorte Saleyards",
        "Mount Compass Southern Livestock Exchange",
        "Dublin South Australian Livestock Exchange",
        "Muchea Livestock Centre",
        "Boyanup Saleyards",
        "Mount Barker Great Southern Regional Cattle Saleyards",
        "Powranna Saleyards",
        "Quoiba Saleyards",
        "Killafaddy Saleyards"
    ]
    
    // MARK: - States
    static let states = [
        "NSW", "VIC", "QLD", "SA", "WA", "TAS", "NT", "ACT"
    ]
    
    // MARK: - Livestock Categories (From ADD HERD Flow PDF)
    static let cattleCategories = [
        "Yearling Steer", "Grown Steer", "Yearling Bull", "Weaner Bull",
        "Weaner Steer", "Grown Bull", "Feeder Steer", "Heifer (Unjoined)", "Heifer (Joined)", 
        "First Calf Heifer", "Breeder", "Dry Cow",
        "Weaner Heifer", "Feeder Heifer", "Cull Cow", "Calves", "Slaughter Cattle"
    ]
    
    static let sheepCategories = [
        "Breeder", "Maiden Ewe (Joined)", "Maiden Ewe (Unjoined)",
        "Dry Ewe", "Cull Ewe", "Weaner Ewe", "Feeder Ewe", "Slaughter Ewe",
        "Lambs", "Weaner Lamb", "Feeder Lamb", "Slaughter Lamb"
    ]
    
    static let pigCategories = [
        "Grower Pig", "Finisher Pig", "Breeder", "Dry Sow", "Cull Sow",
        "Weaner Pig", "Feeder Pig", "Porker", "Baconer",
        "Grower Barrow", "Finisher Barrow"
    ]
    
    static let goatCategories = [
        "Breeder Doe", "Dry Doe", "Cull Doe", "Breeder Buck", "Sale Buck",
        "Mature Wether", "Rangeland Goat", "Capretto", "Chevon"
    ]
    
    // MARK: - Price Sources
    static let priceSources = [
        "Private Sales", "Saleyard", "Feedlot", "Processor", "Restocker"
    ]
}

