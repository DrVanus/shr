//
//  MetalPerlinNoiseView.swift
//  CSAI1
//
//  Created by DM on 3/25/25.
//


import SwiftUI
import MetalKit

struct MetalPerlinNoiseView: UIViewRepresentable {
    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device.")
        }
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.backgroundColor = .clear
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        
        // Create our renderer
        let renderer = Renderer(mtkView: mtkView)
        mtkView.delegate = renderer
        context.coordinator.renderer = renderer
        
        // We can do 30 fps or so
        mtkView.preferredFramesPerSecond = 30
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Nothing special to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var renderer: Renderer?
    }
}

class Renderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState!
    
    private var startTime: CFTimeInterval = CACurrentMediaTime()
    
    struct Uniforms {
        var time: Float
        var resolution: SIMD2<Float>
    }
    
    init(mtkView: MTKView) {
        guard let d = mtkView.device else {
            fatalError("No metal device.")
        }
        device = d
        commandQueue = device.makeCommandQueue()!
        
        super.init()
        
        buildPipelineState(mtkView: mtkView)
    }
    
    private func buildPipelineState(mtkView: MTKView) {
        // Load the Metal library
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not create default Metal library.")
        }
        
        let vertexFunc   = library.makeFunction(name: "v_main")
        let fragmentFunc = library.makeFunction(name: "f_main")
        
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction   = vertexFunc
        pipelineDesc.fragmentFunction = fragmentFunc
        pipelineDesc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDesc)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Called when the view size changes
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        // Time
        let currentTime = CACurrentMediaTime()
        let elapsed = Float(currentTime - startTime)
        
        // Set up our uniforms
        var uniforms = Uniforms(
            time: elapsed,
            resolution: SIMD2<Float>(Float(view.drawableSize.width),
                                     Float(view.drawableSize.height))
        )
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        encoder.setRenderPipelineState(pipelineState)
        
        // buffer(0) in fragment, buffer(1) in vertex
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 0)
        
        // Draw 3 vertices for a full-screen triangle
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
