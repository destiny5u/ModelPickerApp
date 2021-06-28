//
//  Model.swift
//  ModelPickerApp
//
//  Created by Yeonku on 2021/05/06.
//

import UIKit
import RealityKit
import Combine

class Model {
    var modelName:String
    var image:UIImage
    var modelEntity: ModelEntity?
    
    private var cancellabel: AnyCancellable? = nil
    
    init(modelName: String) {
        self.modelName = modelName
        
        self.image = UIImage(named: modelName)!
        
        let filename = modelName + ".usdz"
        self.cancellabel = ModelEntity.loadModelAsync(named: filename)
            .sink(receiveCompletion: {loadCompletion in
                print("DEBUG: unable to load modelEntity \(self.modelName)")
            }, receiveValue: {modelEntity in
                self.modelEntity = modelEntity
                print("DEBUG: Succesefully loaded modelEntity \(self.modelName)")
            })
    }
}
