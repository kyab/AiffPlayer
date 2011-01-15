# MainView.rb
# AiffPlayer
#
# Created by koji on 11/01/16.
# Copyright 2011 __MyCompanyName__. All rights reserved.


class MainView < NSView
	attr_accessor :controller
	def awakeFromNib()
	
		#D&D support
		self.registerForDraggedTypes([NSFilenamesPboardType])
	
	end
	
	
#NSDraggingDestination protocol
	def draggingEntered(sender)
		pboard = sender.draggingPasteboard
		
		#puts pboard.types
		#p pboard.types.class
		
		return NSDragOperationCopy
	end
	
	def performDragOperation(sender)
		puts "----performDragOperation()"
		pboard = sender.draggingPasteboard()

		files = pboard.propertyListForType(NSFilenamesPboardType)
		p files

		if files.length > 0
			@controller.loadAiff(files[0])
		end
	
		return true
	
	end

end
