#
#  Spectrum3DOpenGLController.rb
#  AiffPlayer
#
#  Created by koji on 11/05/05.
#  Copyright 2011 __MyCompanyName__. All rights reserved.
#

class Spectrum3DOpenGLWindowController < NSWindowController
	attr_accessor :view
	attr_accessor :aiff
	def awakeFromNib
		NSLog "#{Spectrum3DOpenGLWindowController} awaked from nib"
	end 
	
	def init
		super.initWithWindowNibName("Spectrum3DOpenGL")
		NSLog "#{self.class} initialized"
		@aiff = nil
		self
	end
	
	def setAiff(aiff)
		@aiff = aiff
		@view.aiff = @aiff
	end
	
	def windowWillLoad()
		
	end
	
	def windowDidLoad()	
		puts "windowDidLoad"
		
	end
	
	def close()
		puts "Spectrum3D(OpenGL) now closed"
		self.window.performClose nil
		
	end
	
	def windowShouldClose(sender)
		true
	end
	
end

