//
//  CameraView.swift
//  ColCo
//
//  Created by Baluta Eugen on 09.03.2022.
//

import SwiftUI

struct CameraView: View {
    @StateObject var viewModel = CameraViewModel()
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    CameraViewRepresentable(color: $viewModel.color, isSnapping: $viewModel.isSnapping)
                        .background(.yellow)
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 5, height: 5)
                        .border(.black, width: 1.5)
                }
                bottomBar
            }
        }
    }
    
    private var bottomBar: some View {
        ZStack {
            HStack {
                Spacer()
                
                Button {
                    
                } label: {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .overlay(
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(viewModel.color)
                                RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.black, lineWidth: 2)
                            }
                        )
                        .frame(width: 55, height: 55)
                }

                Spacer()
                
                Button {
                    viewModel.isSnapping.toggle()
                } label: {
                    Circle()
                        .overlay(
                            ZStack {
                                Circle().fill(.white)
                                Circle().stroke(Color.black, lineWidth: 1)
                            }
                        )
                        .frame(width: 55, height: 55)
                        .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 0)
                        .background(.clear)
                        .foregroundColor(.clear)
                }
                
                Spacer()
                
                Button {
                    
                } label: {
                    Text("Settings")
                        .frame(width: 55, height: 55)
                }

                
                Spacer()
            }
            .padding(.top)
            .background(.green)
        }
    }
}
