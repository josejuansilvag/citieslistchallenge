//
//  DataLoadingView.swift
//  CitiesListChallenge
//
//  Created by Jose Juan Silva Gamino on 23/07/25.
//

import SwiftUI
struct DataLoadingView: View {
    let progress: DataLoadingProgress
    
    var body: some View {
        VStack(spacing: 20) {
            // Icono animado
            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .scaleEffect(progress.isIndeterminate ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: progress.isIndeterminate)
            
            // Título
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            // Descripción
            Text(progress.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            // Barra de progreso
            if !progress.isIndeterminate {
                ProgressView(value: progress.progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 200)
                
                Text("\(Int(progress.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                ProgressView()
                    .scaleEffect(1.2)
            }
            
            // Información adicional
            if case .error(let message) = progress {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var iconName: String {
        switch progress {
        case .idle:
            return "building.2"
        case .downloadingCities:
            return "arrow.down.circle"
        case .processingCities, .savingCities:
            return "gear"
        case .completed:
            return "checkmark.circle"
        case .error:
            return "exclamationmark.triangle"
        }
    }
    
    private var title: String {
        switch progress {
        case .idle:
            return "Ready to Load"
        case .downloadingCities:
            return "Downloading Cities"
        case .processingCities, .savingCities:
            return "Processing Data"
        case .completed:
            return "Data Loaded"
        case .error:
            return "Loading Error"
        }
    }
}
