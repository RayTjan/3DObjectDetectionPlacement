//
//  Model.swift
//  ModelPickerTry
//
//  Created by Hans Richard Alim Natadjaja on 17/08/22.
//

import UIKit
import RealityKit
import Combine

class Model {
    var modelName: String
    var image: UIImage
    var modelEntity: ModelEntity?
    
    private var cancellable: AnyCancellable? = nil
    
    init(modelName: String) {
        self.modelName = modelName
        
        self.image = UIImage(named: modelName) ?? UIImage(named: "teapot")!
        
        let filename = modelName + ".usdz"
        self.cancellable = ModelEntity.loadModelAsync(named: filename)
            .sink(receiveCompletion: { loadCompletion in
                // Handle our error
                print("DEBUG: Unable to load modelEntity for modelName \(self.modelName)")
            }, receiveValue: { modelEntity in
                // Get our modelEntity
                self.modelEntity = modelEntity
                print("DEBUG: Successfullt loaded modelEntity for modelName: \(self.modelName)")
            })
    }
    
}

