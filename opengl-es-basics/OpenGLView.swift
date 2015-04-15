//
//  OpenGLView.swift
//  opengl-es-basics
//
//  Created by David Kouřil on 14/04/15.
//  Copyright (c) 2015 dvdkouril. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import OpenGLES
//import GLKit

struct Vertex {
    var Position: (CFloat, CFloat, CFloat)
    var Color: (CFloat, CFloat, CFloat, CFloat)
}

var Vertices = [
    Vertex(Position: (1, -1, 0), Color: (1, 0, 0, 1)),
    Vertex(Position: (1, 1, 0), Color: (0, 1, 0, 1)),
    Vertex(Position: (-1, 1, 0), Color: (0, 0, 1, 1)),
    Vertex(Position: (-1, -1, 0), Color: (0, 0, 0, 1))
]

var Indices: [GLubyte] = [
    0, 1, 2,
    2, 3, 0
]

class OpenGLView: UIView {
    
    var eaglLayer: CAEAGLLayer!
    var context: EAGLContext!
    var colorRenderBuffer: GLuint = GLuint()
    var positionSlot: GLuint = GLuint()
    var colorSlot: GLuint = GLuint()
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupLayer()
        self.setupContext()
        self.setupRenderBuffer()
        self.setupFrameBuffer()
        self.compileShaders()
        
        self.render()
    }

    override class func layerClass() -> AnyClass {
        return CAEAGLLayer.self
    }
    
    func setupLayer() {
        self.eaglLayer = self.layer as! CAEAGLLayer
        self.eaglLayer.opaque = true
    }
    
    func setupContext() {
        var api: EAGLRenderingAPI = EAGLRenderingAPI.OpenGLES2
        self.context = EAGLContext(API: api)
        
        if self.context == nil {
            println("Failed to initialize OpenGL ES 2.0 context!")
            exit(1)
        }
        
        if !EAGLContext.setCurrentContext(self.context) {
            println("Failed to set current OpenGL context!")
            exit(1)
        }
    }
    
    func setupRenderBuffer() {
        glGenRenderbuffers(1, &self.colorRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), self.colorRenderBuffer)
        self.context.renderbufferStorage(Int(GL_RENDERBUFFER), fromDrawable: self.eaglLayer)
    }
    
    func setupFrameBuffer() {
        var frameBuffer: GLuint = GLuint()
        glGenFramebuffers(1, &frameBuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), self.colorRenderBuffer)
    }
    
    func compileShader(shaderName: String?, shaderType: GLenum) -> GLuint {
        
        var shaderPath = NSBundle.mainBundle().pathForResource(shaderName!, ofType: "glsl")
        var error: NSError? = nil
        //var shaderString = String(contentsOfFile: shaderPath!, encoding: NSUTF8StringEncoding, error: &error)
        var shaderString = NSString(contentsOfFile: shaderPath!, encoding: NSUTF8StringEncoding, error: &error)
        var shaderS = shaderString! as String
        shaderS += "\n"
        shaderString = shaderS as NSString
        
        if shaderString == nil {
            println("Failed to set contents shader of shader file!")
        }
        
        var shaderHandle: GLuint = glCreateShader(shaderType)
        
        //var shaderStringUTF8 = shaderString!.utf8
        var shaderStringUTF8 = shaderString!.UTF8String
        //var shaderStringLength: GLint = GLint() // LOL
        var shaderStringLength: GLint = GLint(shaderString!.length)
        glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength)
        
        glCompileShader(shaderHandle)
        
        var compileSuccess: GLint = GLint()
        
        glGetShaderiv(shaderHandle, GLenum(GL_COMPILE_STATUS), &compileSuccess)
        
        if compileSuccess == GL_FALSE {
            println("Failed to compile shader!")
            exit(1)
        }
        
        var value: GLint = 0
        glGetShaderiv(shaderHandle, GLenum(GL_INFO_LOG_LENGTH), &value)
        var infoLog: [GLchar] = [GLchar](count: Int(value), repeatedValue: 0)
        var infoLogLength: GLsizei = 0
        glGetShaderInfoLog(shaderHandle, value, &infoLogLength, &infoLog)
        var s = NSString(bytes: infoLog, length: Int(infoLogLength), encoding: NSASCIIStringEncoding)
        println(s)
        
        return shaderHandle
        
    }
    
    func compileShaders() {
        
        var vertexShader: GLuint = self.compileShader("SimpleVertex", shaderType: GLenum(GL_VERTEX_SHADER))
        var fragmentShader: GLuint = self.compileShader("SimpleFragment", shaderType: GLenum(GL_FRAGMENT_SHADER))
        
        var programHandle: GLuint = glCreateProgram()
        glAttachShader(programHandle, vertexShader)
        glAttachShader(programHandle, fragmentShader)
        glLinkProgram(programHandle)
        
        var linkSuccess: GLint = GLint()
        glGetProgramiv(programHandle, GLenum(GL_LINK_STATUS), &linkSuccess)
        if linkSuccess == GL_FALSE {
            println("Failed to create shader program!")
           
            var value: GLint = 0
            glGetProgramiv(programHandle, GLenum(GL_INFO_LOG_LENGTH), &value)
            var infoLog: [GLchar] = [GLchar](count: Int(value), repeatedValue: 0)
            var infoLogLength: GLsizei = 0
            glGetProgramInfoLog(programHandle, value, &infoLogLength, &infoLog)
            var s = NSString(bytes: infoLog, length: Int(infoLogLength), encoding: NSASCIIStringEncoding)
            println(s)
            
            //GLchar messages[1024]
            //glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
            exit(1)
        }
        
        glUseProgram(programHandle)
        
        self.positionSlot = GLuint(glGetAttribLocation(programHandle, "Position"))
        self.colorSlot = GLuint(glGetAttribLocation(programHandle, "SourceColor"))
        glEnableVertexAttribArray(self.positionSlot)
        glEnableVertexAttribArray(self.colorSlot)
        
    }
    
    func render() {
        glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        self.context.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }

}
