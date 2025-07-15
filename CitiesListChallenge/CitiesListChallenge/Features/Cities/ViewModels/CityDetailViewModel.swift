//
//  CityDetailViewModel.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 07/07/25.
//

import SwiftUI

//TODO: - I will use this viewmodel to recover aditional data to show in detail view

@Observable
class CityDetailViewModel {
    let city: City
 
    // var additionalInfo: String = "Loading..."

    init(city: City) {
        self.city = city
        // fetchAdditionalData()
    }

    // func fetchAdditionalData() {
    // }
}
