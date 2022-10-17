//
//  ContentView.swift
//  ModelPickerTry
//
//  Created by Hans Richard Alim Natadjaja on 17/08/22.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity

struct ContentView : View {
    @State private var isPlacementEnabled = false
    @State private var selectedModel: Model?
    @State private var modelConfirmedForPlacement: Model?
    @State private var isDeleteModel = false
    @State var coreMLRecognize = false
    @State var raycastResult : [ARRaycastResult] = []
    @State var boundingBox : CGRect = CGRect()
    @State var boxColor : Color = .red
    @State var identificationResult: String = "Nothing"
    
    var body: some View {
        ZStack(alignment: .bottom){
            ARViewContainer(modelConfirmedForReplacement: self.$modelConfirmedForPlacement, isDeleteModel: self.$isDeleteModel, coreMLRecognize: self.$coreMLRecognize, raycastResult: $raycastResult, boundingBox: self.$boundingBox, boxColor: self.$boxColor, identificationResult: $identificationResult)
            
            //THIS IS FOR BOUNDING BOX
//            if(coreMLRecognize == true){
//
//                var currentPath = Path()
//                var secondPath = Path()
//                var thirdPath = Path()
//                Canvas { context, size in
//                    var rectInScreenSize = CGRect(x: boundingBox.minX * size.width,
//                                                  y: boundingBox.minY * size.height,
//                                                  width: boundingBox.width * size.width,
//                                                  height: boundingBox.height * size.height)
//                    var dot1 = CGRect(x: boundingBox.origin.x * size.width,
//                                      y: boundingBox.origin.y * size.height,
//                                      width: size.width / 100,
//                                      height: size.height / 100)
//                    var dot2 = CGRect(x: (boundingBox.origin.x + boundingBox.size.width / 2) * size.width,
//                                      y: (boundingBox.origin.x + boundingBox.size.height / 2) * size.height,
//                                      width: size.width / 100,
//                                      height: size.height / 100)
//                    currentPath.addRect(rectInScreenSize)
//                    secondPath.addRect(dot1)
//                    thirdPath.addRect(dot2)
//                    context.fill(currentPath, with: .color(.green))
//                    context.fill(secondPath, with: .color(.blue))
//                    context.fill(thirdPath, with: .color(.red))
//
//
//
//                }.onAppear {
//                    print("This is printing bounding box1 \(boundingBox)")
//                }
//                Path(boundingBox).stroke(.red, lineWidth: 10).foregroundColor(boxColor)
//            }
            
            Text(identificationResult)
            
            
            
        }
    }
    //#CAMERACODE
    struct ARVariables{
        static var arView = CustomARView(frame: .zero)
    }
    
    
    struct ARViewContainer: UIViewRepresentable {
        @Binding var modelConfirmedForReplacement: Model?
        @Binding var isDeleteModel: Bool
        @Binding var coreMLRecognize : Bool
        @Binding var raycastResult : [ARRaycastResult]
        @Binding var boundingBox : CGRect
        @Binding var boxColor : Color
        @Binding var identificationResult : String
        
        func makeUIView(context: Context) -> ARView {
            
            //        ARVariables.arView = CustomARView(frame: .zero)
            var ar = ARVariables.arView
            ar.completion = { result, raycastResult, boundingBox, identificationResult in
                coreMLRecognize = result
                self.raycastResult = raycastResult
                self.boundingBox = boundingBox
                self.identificationResult = identificationResult
            }
            return ar
            
        }
        
        
        func updateUIView(_ uiView: ARView, context: Context) {
            if(coreMLRecognize == true){
                identificationResult = "something"
                if(raycastResult != []){
                    print("XXXXXX")
                    print("raycastBoundingBox \(boundingBox)")
                    let tempRaycast = raycastResult
                    print("Supposed to be printing model of COREML" )
                    print(tempRaycast)
                    
                    let anchorEntity = AnchorEntity(world: simd_make_float3(tempRaycast.first?.worldTransform.columns.3 ?? [] ))
                    let mesh = MeshResource.generateBox(size: 0.2)
                    let material = SimpleMaterial(color: .blue,roughness: 0.5, isMetallic: true)
                    let modelEntity = ModelEntity(mesh: mesh, materials: [material])
                    
                    
                    anchorEntity.addChild(modelEntity)
                    uiView.scene.addAnchor(anchorEntity)
                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (_) in
                        anchorEntity.removeFromParent()
                    }
                }
            }else{
                identificationResult = "nothing"
            }
            
            
        }
        
        
        
    }
    
    class CustomARView: ARView {
        
        var newView = UIView()
        var completion: ((Bool, [ARRaycastResult], CGRect, String) -> Void)?
        
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
            newView.frame = frameRect
            
            self.layer.addSublayer(newView.layer)
            
            newView.backgroundColor = .red
            self.addSubview(newView)
            
        }
        
        @objc required dynamic init?(coder decoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        var timer = Timer()
        func setupConfig() {
            print("config")
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal, .vertical]
            config.environmentTexturing = .automatic
            
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                config.sceneReconstruction = .mesh
            }
            self.session.run(config)
            setupCoreML()
            
            self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.loopCoreMLUpdate), userInfo: nil, repeats: true)
        }
        
        //ML MODEL
        let carMLModel = try! TestJuan().model
        let serialQueue = DispatchQueue(label: "com.aboveground.dispatchqueueml")
        var visionRequests = [VNRequest]()
        
        func setupCoreML(){
            guard let selectedModel = try? VNCoreMLModel(for: self.carMLModel) else { fatalError("Could not load model")}
            let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
            classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop
            print("setting up COREML")
            visionRequests = [classificationRequest]
        }
        func updateCoreML() {
            //            print("updating COREML")
            let pixbuff : CVPixelBuffer? = (self.session.currentFrame?.capturedImage)
            if pixbuff == nil { return }
            
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixbuff!,options: [:])
            do {
                try imageRequestHandler.perform(self.visionRequests)
            } catch {
                print(error)
            }
            
            
        }
        @objc private func loopCoreMLUpdate() {
            serialQueue.async {
                self.updateCoreML()
            }
        }
        func classificationCompleteHandler(request: VNRequest, error: Error?) {
            
            if error != nil {
                print("Error: " + (error?.localizedDescription)!)
                return
            }
            guard let observations = request.results else {
                return
            }
            
            if !observations.isEmpty {
                print("xxxxxxxxxxxxxxxxxxx")
                print(observations)
                let boundingBox:CGRect = observations[0].value(forKey: "boundingBox") as! CGRect
                print("this is the rect \(boundingBox)")
                let identifiedPoint = CGPoint(x: ((boundingBox.origin.x + (boundingBox.size.width / 2)) * UIScreen.main.bounds.width), y: ((boundingBox.origin.y + (boundingBox.size.height / 2)) * UIScreen.main.bounds.height))
                print(("raycastPoint1 \(identifiedPoint)"))
                let raycastResult = ARVariables.arView.raycast(from: CGPoint(x: identifiedPoint.x, y: identifiedPoint.y), allowing: .estimatedPlane, alignment: .any)
                if(raycastResult != []){
                    print("xxxxxxxxxxxxxxxxxxx")
                    print(observations[0])
                }
                var resultArray : [VNClassificationObservation] = []
                var firstResult: String = "nothing"
                if(observations[0].value(forKey: "labels") != nil){
                    resultArray = observations[0].value(forKey: "labels") as! [VNClassificationObservation]
                    firstResult = resultArray[0].identifier
                    completion?(true, raycastResult, boundingBox,firstResult )
                }
                
            }
            else{
                completion?(false,[], CGRect(), "nothing")
            }
        
        }
    }

}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
