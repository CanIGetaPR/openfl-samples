package;


import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLTexture;
import lime.graphics.opengl.GLUniformLocation;
import lime.utils.Float32Array;
import lime.utils.UInt8Array;
import openfl.display.BitmapData;
import openfl.display.OpenGLView;
import openfl.display.Sprite;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;
import openfl.Assets;


class Main extends Sprite {
	
	
	private var bitmapData:BitmapData;
	private var imageUniform:GLUniformLocation;
	private var modelViewMatrixUniform:GLUniformLocation;
	private var projectionMatrixUniform:GLUniformLocation;
	private var shaderProgram:GLProgram;
	private var texCoordAttribute:Int;
	private var texCoordBuffer:GLBuffer;
	private var texture:GLTexture;
	private var view:OpenGLView;
	private var vertexAttribute:Int;
	private var vertexBuffer:GLBuffer;
	
	
	public function new () {
		
		super ();
		
		bitmapData = Assets.getBitmapData ("assets/openfl.png");
		
		if (OpenGLView.isSupported) {
			
			view = new OpenGLView ();
			
			initializeShaders ();
			
			createBuffers ();
			createTexture ();
			
			view.render = renderView;
			addChild (view);
			
		}
		
	}
	
	
	private function createBuffers ():Void {
		
		var vertices = [
			
			bitmapData.width, bitmapData.height, 0,
			0, bitmapData.height, 0,
			bitmapData.width, 0, 0,
			0, 0, 0
			
		];
		
		vertexBuffer = GL.createBuffer ();
		GL.bindBuffer (GL.ARRAY_BUFFER, vertexBuffer);
		var verticesBytes:Int = Float32Array.BYTES_PER_ELEMENT * vertices.length;
		GL.bufferData (GL.ARRAY_BUFFER, verticesBytes, new Float32Array (vertices), GL.STATIC_DRAW);
		GL.bindBuffer (GL.ARRAY_BUFFER, null);
		
		var texCoords = [
			
			1, 1, 
			0, 1, 
			1, 0, 
			0, 0, 
			
		];
		
		texCoordBuffer = GL.createBuffer ();
		GL.bindBuffer (GL.ARRAY_BUFFER, texCoordBuffer);
		var texCoordsBytes:Int = Float32Array.BYTES_PER_ELEMENT * texCoords.length;
		GL.bufferData (GL.ARRAY_BUFFER, texCoordsBytes, new Float32Array (texCoords), GL.STATIC_DRAW);
		GL.bindBuffer (GL.ARRAY_BUFFER, null);
		
	}
	
	
	private function createTexture ():Void {
		
		texture = GL.createTexture ();
		GL.bindTexture (GL.TEXTURE_2D, texture);
		GL.texParameteri (GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
		GL.texParameteri (GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
		GL.texImage2D (GL.TEXTURE_2D, 0, GL.RGBA, bitmapData.width, bitmapData.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, bitmapData.image.data);
		GL.texParameteri (GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
		GL.texParameteri (GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
		GL.bindTexture (GL.TEXTURE_2D, null);
		
	}
	
	
	private function initializeShaders ():Void {
		
		var vertexShaderSource = 
			
			"attribute vec3 aVertexPosition;
			attribute vec2 aTexCoord;
			varying vec2 vTexCoord;
			
			uniform mat4 uModelViewMatrix;
			uniform mat4 uProjectionMatrix;
			
			void main(void) {
				vTexCoord = aTexCoord;
				gl_Position = uProjectionMatrix * uModelViewMatrix * vec4 (aVertexPosition, 1.0);
			}";
		
		var vertexShader = GL.createShader (GL.VERTEX_SHADER);
		GL.shaderSource (vertexShader, vertexShaderSource);
		GL.compileShader (vertexShader);
		
		if (GL.getShaderParameter (vertexShader, GL.COMPILE_STATUS) == 0) {
			
			throw "Error compiling vertex shader";
			
		}
		
		var fragmentShaderSource = 
			
			"#ifdef GL_ES
			precision mediump float;
			#endif
			varying vec2 vTexCoord;
			uniform sampler2D uImage0;
			
			void main(void)
			{"
				#if (js && html5)
				+ "gl_FragColor = texture2D (uImage0, vTexCoord);" + 
				#else
				+ "gl_FragColor = texture2D (uImage0, vTexCoord).bgra;" + 
				#end
			"}";
		
		var fragmentShader = GL.createShader (GL.FRAGMENT_SHADER);
		GL.shaderSource (fragmentShader, fragmentShaderSource);
		GL.compileShader (fragmentShader);
		
		if (GL.getShaderParameter (fragmentShader, GL.COMPILE_STATUS) == 0) {
			
			throw "Error compiling fragment shader";
			
		}
		
		shaderProgram = GL.createProgram ();
		GL.attachShader (shaderProgram, vertexShader);
		GL.attachShader (shaderProgram, fragmentShader);
		GL.linkProgram (shaderProgram);
		
		if (GL.getProgramParameter (shaderProgram, GL.LINK_STATUS) == 0) {
			
			throw "Unable to initialize the shader program.";
			
		}
		
		vertexAttribute = GL.getAttribLocation (shaderProgram, "aVertexPosition");
		texCoordAttribute = GL.getAttribLocation (shaderProgram, "aTexCoord");
		projectionMatrixUniform = GL.getUniformLocation (shaderProgram, "uProjectionMatrix");
		modelViewMatrixUniform = GL.getUniformLocation (shaderProgram, "uModelViewMatrix");
		imageUniform = GL.getUniformLocation (shaderProgram, "uImage0");
		
	}
	
	
	private function renderView (rect:Rectangle):Void {
		
		GL.viewport (Std.int (rect.x), Std.int (rect.y), Std.int (rect.width), Std.int (rect.height));
		
		GL.clearColor (1.0, 1.0, 1.0, 1.0);
		GL.clear (GL.COLOR_BUFFER_BIT);
		
		GL.enable (GL.BLEND);
		GL.blendFunc (GL.ONE, GL.ONE_MINUS_SRC_ALPHA);
		
		var positionX = (stage.stageWidth - bitmapData.width) / 2;
		var positionY = (stage.stageHeight - bitmapData.height) / 2;
		
		var projectionMatrix = Matrix3D.createOrtho (0, rect.width, rect.height, 0, 1000, -1000);
		var modelViewMatrix = Matrix3D.create2D (positionX, positionY, 1, 0);
		
		GL.useProgram (shaderProgram);
		GL.enableVertexAttribArray (vertexAttribute);
		GL.enableVertexAttribArray (texCoordAttribute);
		
		GL.activeTexture (GL.TEXTURE0);
		GL.bindTexture (GL.TEXTURE_2D, texture);
		
		#if desktop
		GL.enable (GL.TEXTURE_2D);
		#end
		
		GL.bindBuffer (GL.ARRAY_BUFFER, vertexBuffer);
		GL.vertexAttribPointer (vertexAttribute, 3, GL.FLOAT, false, 0, 0);
		GL.bindBuffer (GL.ARRAY_BUFFER, texCoordBuffer);
		GL.vertexAttribPointer (texCoordAttribute, 2, GL.FLOAT, false, 0, 0);
		
		GL.uniformMatrix4fv (projectionMatrixUniform, 1, false, new Float32Array (projectionMatrix.rawData));
		GL.uniformMatrix4fv (modelViewMatrixUniform, 1, false, new Float32Array (modelViewMatrix.rawData));
		GL.uniform1i (imageUniform, 0);
		
		GL.drawArrays (GL.TRIANGLE_STRIP, 0, 4);
		
		GL.bindBuffer (GL.ARRAY_BUFFER, null);
		GL.bindTexture (GL.TEXTURE_2D, null);
		
		#if desktop
		GL.disable (GL.TEXTURE_2D);
		#end
		
		GL.disableVertexAttribArray (vertexAttribute);
		GL.disableVertexAttribArray (texCoordAttribute);
		GL.useProgram (null);
		
	}
	
	
}
