//
//  ContentView.swift
//  ModelPickerApp
//
//  Created by Yeonku on 2021/03/10.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity

struct ContentView : View {
    @State private var isPlacement = false
    @State private var selectedModel: Model?
    @State private var modelConfirmedForPlacement: Model?
    
    private var models: [Model] = {
        // Dynamically get our model filename
        let filemanager = FileManager.default
        let path = Bundle.main.resourcePath
        
        guard let files = try?filemanager.contentsOfDirectory(atPath: path!) else {
        return []
        }
        
        var avaliableModels: [Model] = []
        for filename in files where
            filename.hasSuffix("usdz") {
            let modelName = filename.replacingOccurrences(of: ".usdz", with: "")
            let model = Model(modelName: modelName)
            avaliableModels.append(model)
        }
        
        return avaliableModels
    }()
    
    var body: some View {
//        return ARViewContainer().edgesIgnoringSafeArea(.all)
//        Text("Hello World")
        ZStack(alignment: .bottom, content: {
            ARViewContainer(modelConfirmedForPlacement:     self.$modelConfirmedForPlacement).edgesIgnoringSafeArea(.all)
            
            if self.isPlacement {
                PlacementButtonView(isPlacement: self.$isPlacement, selectedModel: self.$selectedModel, modelConfirmedForPlacement: self.$modelConfirmedForPlacement)
            } else {
                ModelPickerView(isPlacement: self.$isPlacement, selectedModel: self.$selectedModel, models: self.models)
            }
        })
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var modelConfirmedForPlacement: Model?
    
    func makeUIView(context: Context) -> ARView {
        
//        let arView = ARView(frame: .zero)
        
        // Load the "Box" scene from the "Experience" Reality File
//        let boxAnchor = try! Experience.loadBox()

        // Add the box anchor to the scene
//        arView.scene.anchors.append(boxAnchor)
        
//        let config = ARWorldTrackingConfiguration()
//        config.planeDetection = [.horizontal, .vertical]
//        config.environmentTexturing = .automatic
//
//        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
//            config.sceneReconstruction = .mesh
//        }
//
//        arView.session.run(config)
        
        let arView = FocusARView(frame: .zero)

        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
        if let model = self.modelConfirmedForPlacement {
            if model.modelName == "teapot" {
                if let boxScene = try? Experience.loadBox() {
                    boxScene.steelBox?.scale = [5, 0.1, 5]

                    // Do something with box
                    let physics = Physics()
                    
                    let boxEntity = boxScene.children[0].children[0].children[0]
//                  boxEntity.name = "CUBE"
                    print("DEBUG: boxEntity \(boxEntity)")
                    
                    let kinematicComponent: PhysicsBodyComponent = physics.physicsBody!
                    let motionComponent: PhysicsMotionComponent = physics.physicsMotion!

                    boxEntity.components.set(kinematicComponent)
                    boxEntity.components.set(motionComponent)

                    uiView.scene.anchors.append(boxScene)
                }
            } else {
                if let modelEntity = model.modelEntity {
                    print("DEBUG: updateUIView \(model.modelName)")

                    let anchorEntity = AnchorEntity(plane: .any)

                    anchorEntity.addChild(modelEntity.clone(recursive: true))
                    
                    uiView.scene.addAnchor(anchorEntity)
                } else {
                    print("DEBUG: Unable to load \(model.modelName)")
                }
            }

            DispatchQueue.main.async {
                self.modelConfirmedForPlacement = nil
            }
        }
    }
}

class Physics: Entity, HasPhysicsBody, HasPhysicsMotion {
    required init() {
        super.init()

        self.physicsBody = PhysicsBodyComponent(massProperties: .default,
                                                      material: nil,
                                                          mode: .kinematic)

        self.physicsMotion = PhysicsMotionComponent(linearVelocity: [0.1, 0, 0],
                                                   angularVelocity: [1, 3, 5])
    }
}

class FocusARView: ARView {
    enum FocusStyleChoices {
      case classic
      case material
      case color
    }

    /// Style to be displayed in the example
    let focusStyle: FocusStyleChoices = .classic
    var focusEntity: FocusEntity?

    required init(frame frameRect: CGRect) {
      super.init(frame: frameRect)
      self.setupConfig()

      switch self.focusStyle {
      case .color:
        self.focusEntity = FocusEntity(on: self, focus: .plane)
      case .material:
        do {
          let onColor: MaterialColorParameter = try .texture(.load(named: "Add"))
          let offColor: MaterialColorParameter = try .texture(.load(named: "Open"))
          self.focusEntity = FocusEntity(
            on: self,
            style: .colored(
              onColor: onColor, offColor: offColor,
              nonTrackingColor: offColor
            )
          )
        } catch {
          self.focusEntity = FocusEntity(on: self, focus: .classic)
          print("Unable to load plane textures")
          print(error.localizedDescription)
        }
      default:
        self.focusEntity = FocusEntity(on: self, focus: .classic)
      }
    }

    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupConfig() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }

        self.session.run(config)
    }
}

extension FocusARView: FocusEntityDelegate {
  func toTrackingState() {
    print("tracking")
  }
  func toInitializingState() {
    print("initializing")
  }
}

struct ModelPickerView: View {
    @Binding var isPlacement: Bool
    @Binding var selectedModel: Model?
    
    var models: [Model]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true, content: {
            HStack(spacing:10) {
                ForEach(0 ..< self.models.count) {
                    index in
                    Button(action: {
                        print("DEBUG: Selected model \(self.models[index].modelName)")
                        
                        self.selectedModel = self.models[index]
                        
                        self.isPlacement = true
                    }) {
                        Image(uiImage: self.models[index].image)
                            .resizable()
                            .frame(height:80)
                            .aspectRatio(1/1, contentMode:.fit)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                }
            }
        })
        .padding(20)
        .background(Color.black.opacity(0.5))
    }
}

struct PlacementButtonView: View {
    @Binding var isPlacement: Bool
    @Binding var selectedModel: Model?
    @Binding var modelConfirmedForPlacement: Model?
    
    var body: some View {
        HStack {
            // Cancel Button
            Button(action: {
                print("DEBUG: Canceled")
                self.resetPlacementParameters()
            }) {
                Image(systemName: "xmark")
                    .frame(width: 60, height: 60, alignment: .center)
                    .font(.title)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            }
            
            // Confirm Button
            Button(action: {
                print("DEBUG: Confirmed")
                
                self.modelConfirmedForPlacement = self.selectedModel
                self.resetPlacementParameters()
            }) {
                Image(systemName: "checkmark")
                    .frame(width: 60, height: 60, alignment: .center)
                    .font(.title)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            }
        }
    }
    
    func resetPlacementParameters() {
        self.isPlacement = false
        self.selectedModel = nil
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
