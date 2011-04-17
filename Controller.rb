# Controller.rb
# AiffPlayer
#
# Created by koji on 10/12/17.
# Copyright 2010 __MyCompanyName__. All rights reserved.

framework "CoreAudio"

class Controller
	attr_accessor :label_freq,:slider_freq,:wave_view, :label_filename
	attr_accessor :start_btn, :stop_btn;
	attr_accessor :state;
	attr_accessor :window
	
	attr_accessor :spectrum_view;
	
	@spectrum3DWindowController;
	
	def awakeFromNib()
		NSLog("The main Controller awaked from nib")
		NSLog("Running on MacRuby " + MACRUBY_VERSION)
		
		gc = NSGarbageCollector.defaultCollector()
		if (gc)
			NSLog("gc enabled")
		else
			NSLog("gc disabled --- ????")
		end
		
		@auProcessor = AUProcessor.new
	end
	
	def applicationDidBecomeActive(notification)
		puts "applicationDidBecomeActive"
	end
	
	def applicationDidFinishLaunching(notification)
		puts "applicationDidFinishLaunching"
		@spectrum3DWindowController = Spectrum3DWindowController.alloc.init
		@spectrum3DWindowController.showWindow(nil, @spectrum3DWindowController)

	end
	#IB Actions
	
	def hello(sender)
		puts "Controller#hello"
	end
	
	def initCoreAudio(sender)
		@auProcessor.initCoreAudio
		@start_btn.enabled= true;
	end
	
	def start(sender)
		@auProcessor.start
		@start_btn.enabled = false
		@stop_btn.enabled = true;
		@state = :play
	end
	
	def stop(sender)
		#puts "Controller.stop"
		@auProcessor.stop
		@stop_btn.enabled = false
		@start_btn.enabled = true
		@state = :stop
	end
	
	def load(sender)
		loadAiff("/Users/koji/works/2011_02/m/sound_files/MilkeyWay.aif");
		#loadAiff("/Users/koji/work/m/sound_files/DrumnBossa.aif");
		#loadAiff("/Users/koji/work/m/sound_files/kaera_orange.aif");
		#loadAiff("/Users/koji/work/m/sound_files/kaera_orange_short.aif");
		#loadAiff("/Users/koji/work/m/sound_files/kaera_orange_supershort.aif");
	end
	
	#---
	def loadAiff(file)
		@auProcessor.loadAiff(file)
		
		@label_filename.stringValue = file
		
		#set the timer
		NSTimer.scheduledTimerWithTimeInterval(0.02, 
									target:self,
									selector: 'ontimer:',
									userInfo:nil,
									repeats:true)
		
		[@wave_view, @spectrum_view,@spectrum3DWindowController].each do |view|
			view.setAiff(@auProcessor.aiff)
		end
				
		@window.setTitleWithRepresentedFilename(file)

		
	end
	
	def ontimer(timer)
		#return if @state != :play
		#@wave_view.piriodicUpdate
		#@spectrum_view.setNeedsDisplay(true)
	end
	
	#delegation method
	def applicationShouldTerminateAfterLastWindowClosed(sender)
		puts "last window closed"
		return true
	end
	

	def listOutputDevices(sender)
		@auProcessor.listOutputDevices
	end
	
    #TODO: extract out to other sample application
	def listOutputDevices_ruby(sender)
		pSize = Pointer.new("I");
		r = AudioHardwareGetPropertyInfo(KAudioHardwarePropertyDevices, pSize, nil)
		puts pSize[0]
		
		count = pSize[0] / 4 #is there any way to do sizeof(type??)
		pDeviceIDs = Pointer.new("I", count)
		
		r = AudioHardwareGetProperty(KAudioHardwarePropertyDevices, pSize, pDeviceIDs)
		
		deviceIDs = Array.new
		count.times do |i|
			deviceIDs << pDeviceIDs[i]
		end
		#AudioStreamRangedDescription
	
		deviceIDs.each do |devID|
			pName = Pointer.new("c",256)
			pSize = Pointer.new("I")
			pSize.assign(256)
			
			r = AudioDeviceGetProperty(devID,0,0,KAudioDevicePropertyDeviceName, pSize,pName)

			name = String.new
			(pSize[0]-1).times do |n|	#NULL文字も入ってくるので -1。
				name << pName[n]
			end
			puts "device - id:#{devID} name:#{name}"
		end
		
	end


end
	